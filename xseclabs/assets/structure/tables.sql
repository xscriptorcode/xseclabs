
-- ==========================================================
-- RESET LIMPIO
-- ==========================================================
-- Order
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

-- Perfil extendido (misma PK que users para 1:1 limpio)
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

drop trigger if exists on_auth_user_created on auth.users;
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
-- CATÁLOGO DE VULNERABILIDADES
create table public.vuln_catalog (
  vuln_id bigserial primary key,
  code text,
  title text not null,
  description text,
  refs jsonb,  -- <- nombre seguro
  created_at timestamptz not null default now()
);

-- Hallazgo concreto (instancia de vulnerabilidad en un activo)


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
-- POLICIES: USERS / PROFILES / ROLES (GLOBAL)
-- ==========================================================

-- (A) USERS: cada usuario gestiona SOLO su fila
create policy users_self_all
on public.users
as permissive
for all
to authenticated
using (id_uuid = auth.uid())
with check (id_uuid = auth.uid());

-- (B) USERS: super_admin puede TODO
create policy users_super_admin_all
on public.users
as permissive
for all
to authenticated
using (
  exists (
    select 1
    from public.users u
    join public.roles r on r.roles_id = u.roles_id
    where u.id_uuid = auth.uid() and r.type = 'super_admin'
  )
)
with check (
  exists (
    select 1
    from public.users u
    join public.roles r on r.roles_id = u.roles_id
    where u.id_uuid = auth.uid() and r.type = 'super_admin'
  )
);

-- (C) USER_PROFILES: self-access
create policy profiles_self_all
on public.user_profiles
as permissive
for all
to authenticated
using (id_uuid = auth.uid())
with check (id_uuid = auth.uid());

-- (D) USER_PROFILES: super_admin all
create policy profiles_super_admin_all
on public.user_profiles
as permissive
for all
to authenticated
using (
  exists (
    select 1
    from public.users u
    join public.roles r on r.roles_id = u.roles_id
    where u.id_uuid = auth.uid() and r.type = 'super_admin'
  )
)
with check (
  exists (
    select 1
    from public.users u
    join public.roles r on r.roles_id = u.roles_id
    where u.id_uuid = auth.uid() and r.type = 'super_admin'
  )
);

-- (E) ROLES:
--     - lectura para cualquier autenticado
--     - inserción/actualización/borrado solo super_admin
create policy roles_read_all
on public.roles
for select
to authenticated
using (true);

create policy roles_super_admin_insert
on public.roles
for insert
to authenticated
with check (
  exists (
    select 1 from public.users u
    join public.roles r on r.roles_id = u.roles_id
    where u.id_uuid = auth.uid() and r.type = 'super_admin'
  )
);

create policy roles_super_admin_update
on public.roles
for update
to authenticated
using (
  exists (
    select 1 from public.users u
    join public.roles r on r.roles_id = u.roles_id
    where u.id_uuid = auth.uid() and r.type = 'super_admin'
  )
)
with check (
  exists (
    select 1 from public.users u
    join public.roles r on r.roles_id = u.roles_id
    where u.id_uuid = auth.uid() and r.type = 'super_admin'
  )
);

create policy roles_super_admin_delete
on public.roles
for delete
to authenticated
using (
  exists (
    select 1 from public.users u
    join public.roles r on r.roles_id = u.roles_id
    where u.id_uuid = auth.uid() and r.type = 'super_admin'
  )
);

-- ==========================================================
-- POLICIES POR MEMBRESÍA DE PROYECTO (PLANTILLA APLICADA)
-- Un usuario autenticado accede si es miembro del proyecto
-- ==========================================================

-- PROJECTS: el owner (created_by) y los miembros tienen RW
create policy projects_owner_rw
on public.projects
as permissive
for all
to authenticated
using (created_by = auth.uid())
with check (created_by = auth.uid());

create policy projects_members_rw
on public.projects
as permissive
for all
to authenticated
using (exists (
  select 1 from public.project_members pm
  where pm.project_id = projects.project_id
    and pm.user_id = auth.uid()
))
with check (exists (
  select 1 from public.project_members pm
  where pm.project_id = projects.project_id
    and pm.user_id = auth.uid()
));

-- PROJECT_MEMBERS: el usuario ve sus membresías y el owner gestiona todas
create policy pmembers_self_read
on public.project_members
for select
to authenticated
using (user_id = auth.uid());

create policy pmembers_owner_manage
on public.project_members
as permissive
for all
to authenticated
using (exists (
  select 1 from public.projects p
  where p.project_id = project_members.project_id
    and p.created_by = auth.uid()
))
with check (exists (
  select 1 from public.projects p
  where p.project_id = project_members.project_id
    and p.created_by = auth.uid()
));

-- Para facilitar, todos los miembros del proyecto pueden ver a los demás miembros
create policy pmembers_project_read
on public.project_members
for select
to authenticated
using (exists (
  select 1 from public.project_members pm
  where pm.project_id = project_members.project_id
    and pm.user_id = auth.uid()
));

-- ASSETS (miembros RW)
create policy assets_members_rw
on public.assets
as permissive
for all
to authenticated
using (exists (
  select 1 from public.project_members pm
  where pm.project_id = assets.project_id
    and pm.user_id = auth.uid()
))
with check (exists (
  select 1 from public.project_members pm
  where pm.project_id = assets.project_id
    and pm.user_id = auth.uid()
));

-- VULN_CATALOG: solo lectura global para autenticados
create policy vuln_catalog_read_all
on public.vuln_catalog
for select
to authenticated
using (true);

-- FINDINGS (miembros RW)
create policy findings_members_rw
on public.findings
as permissive
for all
to authenticated
using (exists (
  select 1 from public.project_members pm
  where pm.project_id = findings.project_id
    and pm.user_id = auth.uid()
))
with check (exists (
  select 1 from public.project_members pm
  where pm.project_id = findings.project_id
    and pm.user_id = auth.uid()
));

-- INCIDENTS (miembros RW)
create policy incidents_members_rw
on public.incidents
as permissive
for all
to authenticated
using (exists (
  select 1 from public.project_members pm
  where pm.project_id = incidents.project_id
    and pm.user_id = auth.uid()
))
with check (exists (
  select 1 from public.project_members pm
  where pm.project_id = incidents.project_id
    and pm.user_id = auth.uid()
));

-- INCIDENT_ASSETS (miembros RW)
create policy incident_assets_members_rw
on public.incident_assets
as permissive
for all
to authenticated
using (exists (
  select 1 from public.incidents i
  join public.project_members pm on pm.project_id = i.project_id
  where i.incident_id = incident_assets.incident_id
    and pm.user_id = auth.uid()
))
with check (exists (
  select 1 from public.incidents i
  join public.project_members pm on pm.project_id = i.project_id
  where i.incident_id = incident_assets.incident_id
    and pm.user_id = auth.uid()
));

-- INCIDENT_EVENTS (miembros RW)
create policy incident_events_members_rw
on public.incident_events
as permissive
for all
to authenticated
using (exists (
  select 1 from public.incidents i
  join public.project_members pm on pm.project_id = i.project_id
  where i.incident_id = incident_events.incident_id
    and pm.user_id = auth.uid()
))
with check (exists (
  select 1 from public.incidents i
  join public.project_members pm on pm.project_id = i.project_id
  where i.incident_id = incident_events.incident_id
    and pm.user_id = auth.uid()
));

-- EVIDENCE (miembros RW por project_id)
create policy evidence_members_rw
on public.evidence
as permissive
for all
to authenticated
using (exists (
  select 1 from public.project_members pm
  where pm.project_id = evidence.project_id
    and pm.user_id = auth.uid()
))
with check (exists (
  select 1 from public.project_members pm
  where pm.project_id = evidence.project_id
    and pm.user_id = auth.uid()
));

-- ATTACHMENTS (miembros RW)
create policy attachments_members_rw
on public.attachments
as permissive
for all
to authenticated
using (exists (
  select 1 from public.project_members pm
  where pm.project_id = attachments.project_id
    and pm.user_id = auth.uid()
))
with check (exists (
  select 1 from public.project_members pm
  where pm.project_id = attachments.project_id
    and pm.user_id = auth.uid()
));

-- COMMENTS (miembros RW)
create policy comments_members_rw
on public.comments
as permissive
for all
to authenticated
using (exists (
  select 1 from public.project_members pm
  where pm.project_id = comments.project_id
    and pm.user_id = auth.uid()
))
with check (exists (
  select 1 from public.project_members pm
  where pm.project_id = comments.project_id
    and pm.user_id = auth.uid()
));

-- TASKS (miembros RW)
create policy tasks_members_rw
on public.tasks
as permissive
for all
to authenticated
using (exists (
  select 1 from public.project_members pm
  where pm.project_id = tasks.project_id
    and pm.user_id = auth.uid()
))
with check (exists (
  select 1 from public.project_members pm
  where pm.project_id = tasks.project_id
    and pm.user_id = auth.uid()
));

-- IOCs (miembros RW)
create policy iocs_members_rw
on public.iocs
as permissive
for all
to authenticated
using (exists (
  select 1 from public.project_members pm
  where pm.project_id = iocs.project_id
    and pm.user_id = auth.uid()
))
with check (exists (
  select 1 from public.project_members pm
  where pm.project_id = iocs.project_id
    and pm.user_id = auth.uid()
));

-- INCIDENT_IOCS (miembros RW a través del incidente)
create policy incident_iocs_members_rw
on public.incident_iocs
as permissive
for all
to authenticated
using (exists (
  select 1
  from public.incidents i
  join public.project_members pm on pm.project_id = i.project_id
  where i.incident_id = incident_iocs.incident_id
    and pm.user_id = auth.uid()
))
with check (exists (
  select 1
  from public.incidents i
  join public.project_members pm on pm.project_id = i.project_id
  where i.incident_id = incident_iocs.incident_id
    and pm.user_id = auth.uid()
));

-- ATT&CK: lectura global (opcional)
create policy attack_read_all
on public.attack_techniques
for select
to authenticated
using (true);

-- FINDING_TECHNIQUES (miembros RW vía finding -> project_id)
create policy finding_tech_members_rw
on public.finding_techniques
as permissive
for all
to authenticated
using (exists (
  select 1
  from public.findings f
  join public.project_members pm on pm.project_id = f.project_id
  where f.finding_id = finding_techniques.finding_id
    and pm.user_id = auth.uid()
))
with check (exists (
  select 1
  from public.findings f
  join public.project_members pm on pm.project_id = f.project_id
  where f.finding_id = finding_techniques.finding_id
    and pm.user_id = auth.uid()
));

-- INCIDENT_TECHNIQUES (miembros RW vía incident -> project_id)
create policy incident_tech_members_rw
on public.incident_techniques
as permissive
for all
to authenticated
using (exists (
  select 1
  from public.incidents i
  join public.project_members pm on pm.project_id = i.project_id
  where i.incident_id = incident_techniques.incident_id
    and pm.user_id = auth.uid()
))
with check (exists (
  select 1
  from public.incidents i
  join public.project_members pm on pm.project_id = i.project_id
  where i.incident_id = incident_techniques.incident_id
    and pm.user_id = auth.uid()
));

-- ==========================================================
-- (OPCIONAL) SUPER_ADMIN USER
-- change YOUR_AUTH_UID_HERE fot real UUID of Auth > Users
-- ==========================================================
-- insert into public.users (id_uuid, roles_id, is_active)
-- values (
--   'YOUR_AUTH_UID_HERE',
--   (select roles_id from public.roles where type = 'super_admin'),
--   true
-- )
-- on conflict (id_uuid) do update
-- set roles_id = excluded.roles_id, is_active = true;