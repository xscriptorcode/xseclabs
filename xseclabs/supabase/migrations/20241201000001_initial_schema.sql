-- ==========================================================
-- INITIAL SCHEMA: ROLES, USERS, AND USER_PROFILES
-- ==========================================================

-- ==========================================================
-- ROLES DE APLICACIÓN
-- ==========================================================
CREATE TABLE public.roles (
  roles_id bigserial PRIMARY KEY,
  type text UNIQUE NOT NULL,                 -- 'super_admin','admin','moderator','user','viewer'
  description text,
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.roles (type, description) VALUES
  ('super_admin','Acceso total al sistema'),
  ('admin','Administración de la aplicación'),
  ('moderator','Moderación de contenido'),
  ('user','Usuario estándar'),
  ('viewer','Solo lectura');

-- ==========================================================
-- USUARIOS (extiende a auth.users)
-- ==========================================================
CREATE TABLE public.users (
  id_uuid uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  roles_id bigint NOT NULL REFERENCES public.roles(roles_id),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON public.users(roles_id);

-- Perfil extendido (1:1 limpio con users)
CREATE TABLE public.user_profiles (
  id_uuid uuid PRIMARY KEY REFERENCES public.users(id_uuid) ON DELETE CASCADE,
  full_name text,
  username text UNIQUE,
  avatar_url text,
  bio text,
  settings jsonb NOT NULL DEFAULT '{}'::jsonb,
  plan text NOT NULL DEFAULT 'free',
  last_login timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ==========================================================
-- TRIGGER GENERICO updated_at
-- ==========================================================
CREATE OR REPLACE FUNCTION public.tg_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_updated_at_users
BEFORE UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION public.tg_set_updated_at();

CREATE TRIGGER set_updated_at_user_profiles
BEFORE UPDATE ON public.user_profiles
FOR EACH ROW EXECUTE FUNCTION public.tg_set_updated_at();

-- ==========================================================
-- TRIGGER: al crear un auth.user -> crear users + user_profiles
-- Default Rol = 'user'
-- ==========================================================
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  default_role_id bigint;
BEGIN
  SELECT roles_id INTO default_role_id
  FROM public.roles
  WHERE type = 'user';

  INSERT INTO public.users (id_uuid, roles_id)
  VALUES (NEW.id, default_role_id);

  INSERT INTO public.user_profiles (id_uuid)
  VALUES (NEW.id);

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- ==========================================================
-- PROYECTOS / MEMBRESÍAS
-- ==========================================================
CREATE TABLE public.projects (
  project_id bigserial PRIMARY KEY,
  name text NOT NULL,
  description text,
  created_by uuid NOT NULL REFERENCES public.users(id_uuid) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON public.projects(created_by);

CREATE TABLE public.project_members (
  project_id bigint NOT NULL REFERENCES public.projects(project_id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.users(id_uuid) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'member',  -- owner | lead | member | viewer (rol dentro del proyecto)
  added_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (project_id, user_id)
);
CREATE INDEX ON public.project_members(user_id);
CREATE INDEX ON public.project_members(project_id);

-- ==========================================================
-- ACTIVOS
-- ==========================================================
CREATE TABLE public.assets (
  asset_id bigserial PRIMARY KEY,
  project_id bigint NOT NULL REFERENCES public.projects(project_id) ON DELETE CASCADE,
  name text NOT NULL,
  type text NOT NULL,  -- 'host', 'domain', 'ip', 'url', 'service', etc.
  value text NOT NULL,
  description text,
  tags text[],
  metadata jsonb DEFAULT '{}'::jsonb,
  created_by uuid NOT NULL REFERENCES public.users(id_uuid) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON public.assets(project_id);
CREATE INDEX ON public.assets(created_by);
CREATE INDEX ON public.assets(type);

CREATE TRIGGER set_updated_at_assets
BEFORE UPDATE ON public.assets
FOR EACH ROW EXECUTE FUNCTION public.tg_set_updated_at();

-- ==========================================================
-- HELPER FUNCTIONS
-- ==========================================================
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users u
    JOIN public.roles r ON u.roles_id = r.roles_id
    WHERE u.id_uuid = auth.uid()
      AND r.type = 'super_admin'
  );
$$;

-- ==========================================================
-- RLS POLICIES
-- ==========================================================

-- Enable RLS
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assets ENABLE ROW LEVEL SECURITY;

-- ROLES policies
CREATE POLICY roles_read_all
ON public.roles
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY roles_super_admin_insert
ON public.roles
FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

CREATE POLICY roles_super_admin_update
ON public.roles
FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

CREATE POLICY roles_super_admin_delete
ON public.roles
FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- USERS policies
CREATE POLICY users_self_select
ON public.users
FOR SELECT
TO authenticated
USING (id_uuid = auth.uid() OR public.is_super_admin());

CREATE POLICY users_self_mutate
ON public.users
FOR ALL
TO authenticated
USING (id_uuid = auth.uid() OR public.is_super_admin())
WITH CHECK (id_uuid = auth.uid() OR public.is_super_admin());

-- USER_PROFILES policies
CREATE POLICY profiles_self_select
ON public.user_profiles
FOR SELECT
TO authenticated
USING (id_uuid = auth.uid() OR public.is_super_admin());

CREATE POLICY profiles_self_mutate
ON public.user_profiles
FOR ALL
TO authenticated
USING (id_uuid = auth.uid() OR public.is_super_admin())
WITH CHECK (id_uuid = auth.uid() OR public.is_super_admin());

-- PROJECTS policies (basic - will be enhanced later)
CREATE POLICY projects_select_basic
ON public.projects
FOR SELECT
TO authenticated
USING (created_by = auth.uid() OR public.is_super_admin());

CREATE POLICY projects_insert_basic
ON public.projects
FOR INSERT
TO authenticated
WITH CHECK (created_by = auth.uid() OR public.is_super_admin());

CREATE POLICY projects_update_basic
ON public.projects
FOR UPDATE
TO authenticated
USING (created_by = auth.uid() OR public.is_super_admin())
WITH CHECK (created_by = auth.uid() OR public.is_super_admin());

CREATE POLICY projects_delete_basic
ON public.projects
FOR DELETE
TO authenticated
USING (created_by = auth.uid() OR public.is_super_admin());

-- PROJECT_MEMBERS policies (basic)
CREATE POLICY pmembers_select_basic
ON public.project_members
FOR SELECT
TO authenticated
USING (user_id = auth.uid() OR public.is_super_admin());

CREATE POLICY pmembers_insert_basic
ON public.project_members
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid() OR public.is_super_admin());

CREATE POLICY pmembers_update_basic
ON public.project_members
FOR UPDATE
TO authenticated
USING (user_id = auth.uid() OR public.is_super_admin())
WITH CHECK (user_id = auth.uid() OR public.is_super_admin());

CREATE POLICY pmembers_delete_basic
ON public.project_members
FOR DELETE
TO authenticated
USING (user_id = auth.uid() OR public.is_super_admin());

-- ASSETS policies (basic)
CREATE POLICY assets_select_basic
ON public.assets
FOR SELECT
TO authenticated
USING (created_by = auth.uid() OR public.is_super_admin());

CREATE POLICY assets_insert_basic
ON public.assets
FOR INSERT
TO authenticated
WITH CHECK (created_by = auth.uid() OR public.is_super_admin());

CREATE POLICY assets_update_basic
ON public.assets
FOR UPDATE
TO authenticated
USING (created_by = auth.uid() OR public.is_super_admin())
WITH CHECK (created_by = auth.uid() OR public.is_super_admin());

CREATE POLICY assets_delete_basic
ON public.assets
FOR DELETE
TO authenticated
USING (created_by = auth.uid() OR public.is_super_admin());