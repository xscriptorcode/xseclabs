-- Fix infinite recursion in RLS policies
-- Only drop policies if tables exist
DO $$ 
BEGIN
    -- Drop policies only if tables exist
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'projects') THEN
        DROP POLICY IF EXISTS projects_select_members ON public.projects;
        DROP POLICY IF EXISTS projects_insert_authenticated ON public.projects;
        DROP POLICY IF EXISTS projects_update_owner_or_sa ON public.projects;
        DROP POLICY IF EXISTS projects_delete_sa_only ON public.projects;
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'project_members') THEN
        DROP POLICY IF EXISTS pmembers_select_members ON public.project_members;
        DROP POLICY IF EXISTS pmembers_insert_flexible ON public.project_members;
        DROP POLICY IF EXISTS pmembers_update_owner_or_sa ON public.project_members;
        DROP POLICY IF EXISTS pmembers_delete_owner_or_sa ON public.project_members;
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'assets') THEN
        DROP POLICY IF EXISTS assets_member_select ON public.assets;
        DROP POLICY IF EXISTS assets_member_mutate ON public.assets;
    END IF;
END $$;

-- Create simplified policies without recursion - only if tables exist
DO $$
BEGIN
    -- PROJECTS: Simple policies without circular dependencies
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'projects') THEN
        CREATE POLICY projects_select_simple
        ON public.projects
        FOR SELECT
        TO authenticated
        USING (
            created_by = auth.uid()
            OR public.is_super_admin()
        );

        CREATE POLICY projects_insert_simple
        ON public.projects
        FOR INSERT
        TO authenticated
        WITH CHECK (created_by = auth.uid());

        CREATE POLICY projects_update_simple
        ON public.projects
        FOR UPDATE
        TO authenticated
        USING (created_by = auth.uid() OR public.is_super_admin())
        WITH CHECK (created_by = auth.uid() OR public.is_super_admin());

        CREATE POLICY projects_delete_simple
        ON public.projects
        FOR DELETE
        TO authenticated
        USING (public.is_super_admin());
    END IF;

    -- PROJECT_MEMBERS: Simple policies without recursion
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'project_members') THEN
        CREATE POLICY pmembers_select_simple
        ON public.project_members
        FOR SELECT
        TO authenticated
        USING (
            user_id = auth.uid()
            OR public.is_super_admin()
        );

        CREATE POLICY pmembers_insert_simple
        ON public.project_members
        FOR INSERT
        TO authenticated
        WITH CHECK (
            public.is_super_admin()
            OR user_id = auth.uid()
        );

        CREATE POLICY pmembers_update_simple
        ON public.project_members
        FOR UPDATE
        TO authenticated
        USING (
            user_id = auth.uid()
            OR public.is_super_admin()
        )
        WITH CHECK (
            user_id = auth.uid()
            OR public.is_super_admin()
        );

        CREATE POLICY pmembers_delete_simple
        ON public.project_members
        FOR DELETE
        TO authenticated
        USING (
            user_id = auth.uid()
            OR public.is_super_admin()
        );
    END IF;

    -- ASSETS: Simple policies
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'assets') THEN
        CREATE POLICY assets_select_simple
        ON public.assets
        FOR SELECT
        TO authenticated
        USING (public.is_super_admin());

        CREATE POLICY assets_mutate_simple
        ON public.assets
        FOR ALL
        TO authenticated
        USING (public.is_super_admin())
        WITH CHECK (public.is_super_admin());
    END IF;
END $$;