-- ==========================================================
-- COMPLETE CONTENT POLICIES FOR PROJECT MANAGEMENT
-- Enables full RW access for project members on existing tables
-- ==========================================================

-- ==========================================================
-- HELPER FUNCTIONS (if not already exist)
-- ==========================================================
CREATE OR REPLACE FUNCTION public.is_project_member(p_project_id bigint)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.project_members pm
    WHERE pm.project_id = p_project_id
      AND pm.user_id = auth.uid()
  ) OR EXISTS (
    SELECT 1
    FROM public.projects p
    WHERE p.project_id = p_project_id
      AND p.created_by = auth.uid()
  ) OR public.is_super_admin();
$$;

-- ==========================================================
-- DROP EXISTING POLICIES TO AVOID CONFLICTS
-- ==========================================================

-- Drop existing basic policies for assets
DROP POLICY IF EXISTS assets_select_basic ON public.assets;
DROP POLICY IF EXISTS assets_insert_basic ON public.assets;
DROP POLICY IF EXISTS assets_update_basic ON public.assets;
DROP POLICY IF EXISTS assets_delete_basic ON public.assets;

-- Drop existing basic policies for projects
DROP POLICY IF EXISTS projects_select_basic ON public.projects;
DROP POLICY IF EXISTS projects_insert_basic ON public.projects;
DROP POLICY IF EXISTS projects_update_basic ON public.projects;
DROP POLICY IF EXISTS projects_delete_basic ON public.projects;

-- Drop existing basic policies for project_members
DROP POLICY IF EXISTS pmembers_select_basic ON public.project_members;
DROP POLICY IF EXISTS pmembers_insert_basic ON public.project_members;
DROP POLICY IF EXISTS pmembers_update_basic ON public.project_members;
DROP POLICY IF EXISTS pmembers_delete_basic ON public.project_members;

-- ==========================================================
-- ENHANCED POLICIES FOR EXISTING TABLES
-- ==========================================================

-- PROJECTS policies (enhanced)
CREATE POLICY projects_select_members
ON public.projects
FOR SELECT
TO authenticated
USING (
  public.is_project_member(project_id) OR
  public.is_super_admin()
);

CREATE POLICY projects_insert_authenticated
ON public.projects
FOR INSERT
TO authenticated
WITH CHECK (created_by = auth.uid());

CREATE POLICY projects_update_owner_admin
ON public.projects
FOR UPDATE
TO authenticated
USING (
  created_by = auth.uid() OR
  public.is_super_admin()
)
WITH CHECK (
  created_by = auth.uid() OR
  public.is_super_admin()
);

CREATE POLICY projects_delete_admin
ON public.projects
FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- PROJECT_MEMBERS policies (enhanced)
CREATE POLICY pmembers_select_own_or_project
ON public.project_members
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR
  public.is_project_member(project_id) OR
  public.is_super_admin()
);

CREATE POLICY pmembers_insert_creator_owner_admin
ON public.project_members
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.project_id = project_members.project_id
      AND p.created_by = auth.uid()
  ) OR
  EXISTS (
    SELECT 1 FROM public.project_members pm
    WHERE pm.project_id = project_members.project_id
      AND pm.user_id = auth.uid()
      AND pm.role IN ('owner', 'lead')
  ) OR
  public.is_super_admin()
);

CREATE POLICY pmembers_update_creator_owner_admin
ON public.project_members
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.project_id = project_members.project_id
      AND p.created_by = auth.uid()
  ) OR
  EXISTS (
    SELECT 1 FROM public.project_members pm
    WHERE pm.project_id = project_members.project_id
      AND pm.user_id = auth.uid()
      AND pm.role IN ('owner', 'lead')
  ) OR
  public.is_super_admin()
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.project_id = project_members.project_id
      AND p.created_by = auth.uid()
  ) OR
  EXISTS (
    SELECT 1 FROM public.project_members pm
    WHERE pm.project_id = project_members.project_id
      AND pm.user_id = auth.uid()
      AND pm.role IN ('owner', 'lead')
  ) OR
  public.is_super_admin()
);

CREATE POLICY pmembers_delete_creator_owner_admin
ON public.project_members
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.project_id = project_members.project_id
      AND p.created_by = auth.uid()
  ) OR
  EXISTS (
    SELECT 1 FROM public.project_members pm
    WHERE pm.project_id = project_members.project_id
      AND pm.user_id = auth.uid()
      AND pm.role IN ('owner', 'lead')
  ) OR
  public.is_super_admin()
);

-- ASSETS policies (enhanced for project members)
CREATE POLICY assets_select_project_members
ON public.assets
FOR SELECT
TO authenticated
USING (public.is_project_member(project_id));

CREATE POLICY assets_insert_project_members
ON public.assets
FOR INSERT
TO authenticated
WITH CHECK (public.is_project_member(project_id));

CREATE POLICY assets_update_project_members
ON public.assets
FOR UPDATE
TO authenticated
USING (public.is_project_member(project_id))
WITH CHECK (public.is_project_member(project_id));

CREATE POLICY assets_delete_project_members
ON public.assets
FOR DELETE
TO authenticated
USING (public.is_project_member(project_id));