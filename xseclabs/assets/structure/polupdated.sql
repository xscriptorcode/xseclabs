-- ==========================================================
-- RESET LIMPIO (orden seguro)
-- ==========================================================
drop trigger if exists on_auth_user_created on auth.users;

drop function if exists public.handle_new_auth_user() cascade;
drop function if exists public.is_super_admin() cascade;
drop function if exists public.has_role(text) cascade;
drop function if exists public.is_project_member(bigint) cascade;
drop function if exists public.is_project_owner(bigint) cascade;
drop function if exists public.member_via_incident(bigint) cascade;
drop function if exists public.member_via_finding(bigint) cascade;

drop function if exists public.tg_set_updated_at() cascade;

drop table if exists public.incident_techniques cascade;
drop table if exists public.finding_techniques cascade;
drop table if exists public.attack_techniques cascade;

drop table if exists public.incident_iocs cascade;
drop table if exists public.iocs cascade;

drop table if exists public.tasks cascade;
drop table if exists public.comments cascade;
drop table if exists public.attachments cascade;
drop table if exists public.evidence cascade;

drop table if exists public.incident_events cascade;
drop table if exists public.incident_assets cascade;
drop table if exists public.incidents cascade;

drop table if exists public.findings cascade;
drop table if exists public.vuln_catalog cascade;

drop table if exists public.assets cascade;
drop table if exists public.project_members cascade;
drop table if exists public.projects cascade;

drop table if exists public.user_profiles cascade;
drop table if exists public.users cascade;
drop table if exists public.roles cascade;

-- ==========================================================
-- ROLES DE APLICACIÓN
-- ==========================================================
create table public.roles (
  roles_id bigserial primary key,
  type text unique not null,                 -- 'super_admin','admin','moderator','user','viewer'
  description text,
  created_at timestamptz not null default now()
);

insert into public.roles (type, description) values
  ('super_admin','Acceso total al sistema'),
  ('admin','Administración de la aplicación'),
  ('moderator','Moderación de contenido'),
  ('user','Usuario estándar'),
  ('viewer','Solo lectura');

-- ==========================================================
-- USUARIOS (extiende a auth.users)
-- ==========================================================
create table public.users (
  id_uuid uuid primary key references auth.users(id) on delete cascade,
  roles_id bigint not null references public.roles(roles_id),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on public.users(roles_id);

-- Perfil extendido (1:1 limpio con users)
create table public.user_profiles (
  id_uuid uuid primary key references public.users(id_uuid) on delete cascade,
  full_name text,
  username text unique,
  avatar_url text,
  bio text,
  settings jsonb not null default '{}'::jsonb,
  plan text not null default 'free',
  last_login timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ==========================================================
-- TRIGGER GENERICO updated_at
-- ==========================================================
create or replace function public.tg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- attach updated_at trigger where applicable
drop trigger if exists set_updated_at_users on public.users;
create trigger set_updated_at_users
before update on public.users
for each row execute function public.tg_set_updated_at();

drop trigger if exists set_updated_at_user_profiles on public.user_profiles;
create trigger set_updated_at_user_profiles
before update on public.user_profiles
for each row execute function public.tg_set_updated_at();

-- ==========================================================
-- TRIGGER: al crear un auth.user -> crear users + user_profiles
-- Default Rol = 'user'
-- ==========================================================
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  default_role_id bigint;
begin
  select roles_id into default_role_id
  from public.roles
  where type = 'user';

  insert into public.users (id_uuid, roles_id)
  values (new.id, default_role_id);

  insert into public.user_profiles (id_uuid)
  values (new.id);

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

-- ==========================================================
-- PROYECTOS / MEMBRESÍAS
-- ==========================================================
create table public.projects (
  project_id bigserial primary key,
  name text not null,
  description text,
  created_by uuid not null references public.users(id_uuid) on delete restrict,
  created_at timestamptz not null default now()
);
create index on public.projects(created_by);

create table public.project_members (
  project_id bigint not null references public.projects(project_id) on delete cascade,
  user_id uuid not null references public.users(id_uuid) on delete cascade,
  role text not null default 'member',  -- owner | lead | member | viewer (rol dentro del proyecto)
  added_at timestamptz not null default now(),
  primary key (project_id, user_id)
);
create index on public.project_members(user_id);
create index on public.project_members(project_id);

-- ==========================================================
-- ACTIVOS
-- ==========================================================
create table public.assets (
  asset_id bigserial primary key,
  project_id bigint not null references public.projects(project_id) on delete cascade,
  name text not null,
  type text,               -- host|webapp|api|cloud|mobile|network_device|user...
  identifier text,         -- fqdn/ip/url/account-id/etc.
  criticality text,        -- low|medium|high|critical
  owner text,
  notes text,
  created_at timestamptz not null default now()
);
create index on public.assets(project_id);

-- ==========================================================
-- CATÁLOGO DE VULNERABILIDADES + HALLAZGOS
-- ==========================================================
create table public.vuln_catalog (
  vuln_id bigserial primary key,
  code text,
  title text not null,
  description text,
  refs jsonb,
  created_at timestamptz not null default now()
);

create table public.findings (
  finding_id bigserial primary key,
  project_id bigint not null references public.projects(project_id) on delete cascade,
  asset_id bigint references public.assets(asset_id) on delete set null,
  vuln_id bigint references public.vuln_catalog(vuln_id) on delete set null,
  title text not null,
  severity text not null check (severity in ('info','low','medium','high','critical')),
  status text not null default 'open'
    check (status in ('open','in_progress','resolved','accepted','false_positive')),
  details text,
  remediation text,
  created_by uuid references public.users(id_uuid) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on public.findings(project_id);
create index on public.findings(asset_id);

drop trigger if exists set_updated_at_findings on public.findings;
create trigger set_updated_at_findings
before update on public.findings
for each row execute function public.tg_set_updated_at();

-- ==========================================================
-- INCIDENTES + RELACIONES + TIMELINE
-- ==========================================================
create table public.incidents (
  incident_id bigserial primary key,
  project_id bigint not null references public.projects(project_id) on delete cascade,
  title text not null,
  severity text not null check (severity in ('low','medium','high','critical')),
  status text not null default 'open' check (status in ('open','triage','containment','eradication','recovery','closed')),
  category text,           -- phishing|malware|ransomware|data_leak|intrusion...
  detected_at timestamptz,
  closed_at timestamptz,
  created_by uuid references public.users(id_uuid) on delete set null,
  created_at timestamptz not null default now()
);
create index on public.incidents(project_id);

create table public.incident_assets (
  incident_id bigint not null references public.incidents(incident_id) on delete cascade,
  asset_id bigint not null references public.assets(asset_id) on delete cascade,
  primary key (incident_id, asset_id)
);

create table public.incident_events (
  event_id bigserial primary key,
  incident_id bigint not null references public.incidents(incident_id) on delete cascade,
  occurred_at timestamptz not null default now(),
  author uuid references public.users(id_uuid) on delete set null,
  type text,               -- note|action|alert|observable|status_change
  summary text not null,
  details jsonb
);
create index on public.incident_events(incident_id);

-- ==========================================================
-- EVIDENCIAS / ADJUNTOS / COMENTARIOS / TAREAS
-- ==========================================================
create table public.evidence (
  evidence_id bigserial primary key,
  project_id bigint not null references public.projects(project_id) on delete cascade,
  finding_id bigint references public.findings(finding_id) on delete set null,
  incident_id bigint references public.incidents(incident_id) on delete set null,
  title text,
  storage_url text,        -- ruta de bucket
  hash text,
  notes text,
  added_by uuid references public.users(id_uuid) on delete set null,
  created_at timestamptz not null default now()
);
create index on public.evidence(project_id);

create table public.attachments (
  attachment_id bigserial primary key,
  project_id bigint not null references public.projects(project_id) on delete cascade,
  entity_type text not null,      -- finding|incident|asset|event
  entity_id bigint not null,
  storage_url text not null,
  filename text,
  content_type text,
  size_bytes bigint,
  uploaded_by uuid references public.users(id_uuid) on delete set null,
  uploaded_at timestamptz not null default now()
);
create index on public.attachments(project_id);

create table public.comments (
  comment_id bigserial primary key,
  project_id bigint not null references public.projects(project_id) on delete cascade,
  entity_type text not null,
  entity_id bigint not null,
  author uuid references public.users(id_uuid) on delete set null,
  body text not null,
  created_at timestamptz not null default now()
);
create index on public.comments(project_id);

create table public.tasks (
  task_id bigserial primary key,
  project_id bigint not null references public.projects(project_id) on delete cascade,
  entity_type text,        -- opcional: finding|incident
  entity_id bigint,
  title text not null,
  status text not null default 'open' check (status in ('open','doing','blocked','done')),
  priority text not null default 'medium' check (priority in ('low','medium','high','urgent')),
  assignee uuid references public.users(id_uuid) on delete set null,
  due_date date,
  created_by uuid references public.users(id_uuid) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on public.tasks(project_id);

drop trigger if exists set_updated_at_tasks on public.tasks;
create trigger set_updated_at_tasks
before update on public.tasks
for each row execute function public.tg_set_updated_at();

-- ==========================================================
-- IoCs / ATT&CK
-- ==========================================================
create table public.iocs (
  ioc_id bigserial primary key,
  project_id bigint not null references public.projects(project_id) on delete cascade,
  type text not null,             -- ip|domain|url|hash|email|registry|process|yara...
  value text not null,
  source text,                    -- feed|tool|manual|case
  first_seen timestamptz,
  last_seen timestamptz,
  confidence int,                 -- 0..100
  created_at timestamptz not null default now(),
  unique (project_id, type, value)
);
create index on public.iocs(project_id);

create table public.incident_iocs (
  incident_id bigint not null references public.incidents(incident_id) on delete cascade,
  ioc_id bigint not null references public.iocs(ioc_id) on delete cascade,
  primary key (incident_id, ioc_id)
);

create table public.attack_techniques (
  technique_id text primary key,  -- T1059, T1566, ...
  name text
);

create table public.finding_techniques (
  finding_id bigint not null references public.findings(finding_id) on delete cascade,
  technique_id text not null references public.attack_techniques(technique_id) on delete cascade,
  primary key (finding_id, technique_id)
);

create table public.incident_techniques (
  incident_id bigint not null references public.incidents(incident_id) on delete cascade,
  technique_id text not null references public.attack_techniques(technique_id) on delete cascade,
  primary key (incident_id, technique_id)
);

-- ==========================================================
-- RLS: ACTIVAR EN TODAS LAS TABLAS
-- ==========================================================
alter table public.roles               enable row level security;
alter table public.users               enable row level security;
alter table public.user_profiles       enable row level security;

alter table public.projects            enable row level security;
alter table public.project_members     enable row level security;
alter table public.assets              enable row level security;
alter table public.vuln_catalog        enable row level security;
alter table public.findings            enable row level security;
alter table public.incidents           enable row level security;
alter table public.incident_assets     enable row level security;
alter table public.incident_events     enable row level security;
alter table public.evidence            enable row level security;
alter table public.attachments         enable row level security;
alter table public.comments            enable row level security;
alter table public.tasks               enable row level security;
alter table public.iocs                enable row level security;
alter table public.incident_iocs       enable row level security;
alter table public.attack_techniques   enable row level security;
alter table public.finding_techniques  enable row level security;
alter table public.incident_techniques enable row level security;

-- ==========================================================
-- HELPERS DE AUTORIZACIÓN (evitan recursividad)
-- ==========================================================
-- Nota: SECURITY DEFINER + search_path fijo; devuelven booleanos.

create or replace function public.has_role(p_role text)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.users u
    join public.roles r on r.roles_id = u.roles_id
    where u.id_uuid = auth.uid() and r.type = p_role
  );
$$;

create or replace function public.is_super_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select public.has_role('super_admin');
$$;

create or replace function public.is_project_member(p_project_id bigint)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.project_members pm
    where pm.project_id = p_project_id
      and pm.user_id = auth.uid()
  ) or exists (
    -- el creador del proyecto también cuenta como miembro implícito
    select 1
    from public.projects p
    where p.project_id = p_project_id
      and p.created_by = auth.uid()
  ) or public.is_super_admin();
$$;

create or replace function public.is_project_owner(p_project_id bigint)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.projects p
    where p.project_id = p_project_id
      and p.created_by = auth.uid()
  ) or public.is_super_admin();
$$;

create or replace function public.member_via_incident(p_incident_id bigint)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select public.is_project_member(i.project_id)
  from public.incidents i
  where i.incident_id = p_incident_id;
$$;

create or replace function public.member_via_finding(p_finding_id bigint)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select public.is_project_member(f.project_id)
  from public.findings f
  where f.finding_id = p_finding_id;
$$;

-- ==========================================================
-- POLICIES: USERS / PROFILES / ROLES (GLOBAL)
-- ==========================================================

-- USERS: cada usuario gestiona SOLO su fila
create policy users_self_select
on public.users
for select
to authenticated
using (id_uuid = auth.uid() or public.is_super_admin());

create policy users_self_mutate
on public.users
for all
to authenticated
using (id_uuid = auth.uid() or public.is_super_admin())
with check (id_uuid = auth.uid() or public.is_super_admin());

-- USER_PROFILES: self + super_admin
create policy profiles_self_select
on public.user_profiles
for select
to authenticated
using (id_uuid = auth.uid() or public.is_super_admin());

create policy profiles_self_mutate
on public.user_profiles
for all
to authenticated
using (id_uuid = auth.uid() or public.is_super_admin())
with check (id_uuid = auth.uid() or public.is_super_admin());

-- ROLES:
create policy roles_read_all
on public.roles
for select
to authenticated
using (true);

create policy roles_super_admin_insert
on public.roles
for insert
to authenticated
with check (public.is_super_admin());

create policy roles_super_admin_update
on public.roles
for update
to authenticated
using (public.is_super_admin())
with check (public.is_super_admin());

create policy roles_super_admin_delete
on public.roles
for delete
to authenticated
using (public.is_super_admin());

-- ==========================================================
-- POLICIES POR MEMBRESÍA (SIN RECURSIVIDAD)
-- Usan funciones booleanas SECURITY DEFINER
-- ==========================================================

-- PROJECTS: owner RW; miembros R/W (owner implícito en helper)
create policy projects_member_select
on public.projects
for select
to authenticated
using (public.is_project_member(project_id));

create policy projects_member_mutate
on public.projects
for all
to authenticated
using (public.is_project_owner(project_id))
with check (public.is_project_owner(project_id));

-- PROJECT_MEMBERS:
--   - ver miembros si eres miembro del proyecto
--   - gestionar membresías sólo el owner (o super_admin)
create policy pmembers_member_select
on public.project_members
for select
to authenticated
using (public.is_project_member(project_id));

create policy pmembers_owner_mutate
on public.project_members
for all
to authenticated
using (public.is_project_owner(project_id))
with check (public.is_project_owner(project_id));

-- ASSETS (miembros RW)
create policy assets_member_select
on public.assets
for select
to authenticated
using (public.is_project_member(project_id));

create policy assets_member_mutate
on public.assets
for all
to authenticated
using (public.is_project_member(project_id))
with check (public.is_project_member(project_id));

-- VULN_CATALOG: lectura global autenticados
create policy vuln_catalog_read_all
on public.vuln_catalog
for select
to authenticated
using (true);

-- FINDINGS (miembros RW)
create policy findings_member_select
on public.findings
for select
to authenticated
using (public.is_project_member(project_id));

create policy findings_member_mutate
on public.findings
for all
to authenticated
using (public.is_project_member(project_id))
with check (public.is_project_member(project_id));

-- INCIDENTS (miembros RW)
create policy incidents_member_select
on public.incidents
for select
to authenticated
using (public.is_project_member(project_id));

create policy incidents_member_mutate
on public.incidents
for all
to authenticated
using (public.is_project_member(project_id))
with check (public.is_project_member(project_id));

-- INCIDENT_ASSETS (miembros RW vía incidente)
create policy incident_assets_member_select
on public.incident_assets
for select
to authenticated
using (public.member_via_incident(incident_id));

create policy incident_assets_member_mutate
on public.incident_assets
for all
to authenticated
using (public.member_via_incident(incident_id))
with check (public.member_via_incident(incident_id));

-- INCIDENT_EVENTS (miembros RW vía incidente)
create policy incident_events_member_select
on public.incident_events
for select
to authenticated
using (public.member_via_incident(incident_id));

create policy incident_events_member_mutate
on public.incident_events
for all
to authenticated
using (public.member_via_incident(incident_id))
with check (public.member_via_incident(incident_id));

-- EVIDENCE (miembros RW por project_id directo)
create policy evidence_member_select
on public.evidence
for select
to authenticated
using (public.is_project_member(project_id));

create policy evidence_member_mutate
on public.evidence
for all
to authenticated
using (public.is_project_member(project_id))
with check (public.is_project_member(project_id));

-- ATTACHMENTS (miembros RW)
create policy attachments_member_select
on public.attachments
for select
to authenticated
using (public.is_project_member(project_id));

create policy attachments_member_mutate
on public.attachments
for all
to authenticated
using (public.is_project_member(project_id))
with check (public.is_project_member(project_id));

-- COMMENTS (miembros RW)
create policy comments_member_select
on public.comments
for select
to authenticated
using (public.is_project_member(project_id));

create policy comments_member_mutate
on public.comments
for all
to authenticated
using (public.is_project_member(project_id))
with check (public.is_project_member(project_id));

-- TASKS (miembros RW)
create policy tasks_member_select
on public.tasks
for select
to authenticated
using (public.is_project_member(project_id));

create policy tasks_member_mutate
on public.tasks
for all
to authenticated
using (public.is_project_member(project_id))
with check (public.is_project_member(project_id));

-- IOCs (miembros RW)
create policy iocs_member_select
on public.iocs
for select
to authenticated
using (public.is_project_member(project_id));

create policy iocs_member_mutate
on public.iocs
for all
to authenticated
using (public.is_project_member(project_id))
with check (public.is_project_member(project_id));

-- INCIDENT_IOCS (miembros RW vía incidente)
create policy incident_iocs_member_select
on public.incident_iocs
for select
to authenticated
using (public.member_via_incident(incident_id));

create policy incident_iocs_member_mutate
on public.incident_iocs
for all
to authenticated
using (public.member_via_incident(incident_id))
with check (public.member_via_incident(incident_id));

-- ATT&CK: lectura global
create policy attack_read_all
on public.attack_techniques
for select
to authenticated
using (true);

-- FINDING_TECHNIQUES (miembros RW vía finding)
create policy finding_tech_member_select
on public.finding_techniques
for select
to authenticated
using (public.member_via_finding(finding_id));

create policy finding_tech_member_mutate
on public.finding_techniques
for all
to authenticated
using (public.member_via_finding(finding_id))
with check (public.member_via_finding(finding_id));

-- INCIDENT_TECHNIQUES (miembros RW vía incidente)
create policy incident_tech_member_select
on public.incident_techniques
for select
to authenticated
using (public.member_via_incident(incident_id));

create policy incident_tech_member_mutate
on public.incident_techniques
for all
to authenticated
using (public.member_via_incident(incident_id))
with check (public.member_via_incident(incident_id));
