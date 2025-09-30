-- Enhanced RLS policies for projects, project_members, and assets
-- Drop previous simple policies and create enhanced ones

DO $$ 
BEGIN
    -- Drop simple policies only if tables exist
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'projects') THEN
        DROP POLICY IF EXISTS projects_select_simple ON public.projects;
        DROP POLICY IF EXISTS projects_insert_simple ON public.projects;
        DROP POLICY IF EXISTS projects_update_simple ON public.projects;
        DROP POLICY IF EXISTS projects_delete_simple ON public.projects;
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'project_members') THEN
        DROP POLICY IF EXISTS pmembers_select_simple ON public.project_members;
        DROP POLICY IF EXISTS pmembers_insert_simple ON public.project_members;
        DROP POLICY IF EXISTS pmembers_update_simple ON public.project_members;
        DROP POLICY IF EXISTS pmembers_delete_simple ON public.project_members;
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'assets') THEN
        DROP POLICY IF EXISTS assets_select_simple ON public.assets;
        DROP POLICY IF EXISTS assets_mutate_simple ON public.assets;
    END IF;
END $$;

-- Create enhanced policies - only if tables exist
DO $$
BEGIN
    -- PROJECTS: Enhanced policies with project membership
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'projects') THEN
        CREATE POLICY projects_select_enhanced
        ON public.projects
        FOR SELECT
        TO authenticated
        USING (
            created_by = auth.uid()
            OR public.is_super_admin()
        );

        CREATE POLICY projects_insert_enhanced
        ON public.projects
        FOR INSERT
        TO authenticated
        WITH CHECK (created_by = auth.uid());

        CREATE POLICY projects_update_enhanced
        ON public.projects
        FOR UPDATE
        TO authenticated
        USING (
            created_by = auth.uid()
            OR public.is_super_admin()
        )
        WITH CHECK (
            created_by = auth.uid()
            OR public.is_super_admin()
        );

        CREATE POLICY projects_delete_enhanced
        ON public.projects
        FOR DELETE
        TO authenticated
        USING (public.is_super_admin());
    END IF;

    -- PROJECT_MEMBERS: Enhanced policies
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'project_members') THEN
        CREATE POLICY pmembers_select_enhanced
         ON public.project_members
         FOR SELECT
         TO authenticated
         USING (
             user_id = auth.uid()
             OR public.is_super_admin()
             OR EXISTS (
                 SELECT 1 FROM public.projects p
                 WHERE p.project_id = project_members.project_id
                 AND p.created_by = auth.uid()
             )
         );

        CREATE POLICY pmembers_insert_enhanced
         ON public.project_members
         FOR INSERT
         TO authenticated
         WITH CHECK (
             public.is_super_admin()
             OR user_id = auth.uid()
             OR EXISTS (
                 SELECT 1 FROM public.projects p
                 WHERE p.project_id = project_members.project_id
                 AND p.created_by = auth.uid()
             )
         );

        CREATE POLICY pmembers_update_enhanced
         ON public.project_members
         FOR UPDATE
         TO authenticated
         USING (
             user_id = auth.uid()
             OR public.is_super_admin()
             OR EXISTS (
                 SELECT 1 FROM public.projects p
                 WHERE p.project_id = project_members.project_id
                 AND p.created_by = auth.uid()
             )
         )
         WITH CHECK (
             user_id = auth.uid()
             OR public.is_super_admin()
             OR EXISTS (
                 SELECT 1 FROM public.projects p
                 WHERE p.project_id = project_members.project_id
                 AND p.created_by = auth.uid()
             )
         );

        CREATE POLICY pmembers_delete_enhanced
         ON public.project_members
         FOR DELETE
         TO authenticated
         USING (
             user_id = auth.uid()
             OR public.is_super_admin()
             OR EXISTS (
                 SELECT 1 FROM public.projects p
                 WHERE p.project_id = project_members.project_id
                 AND p.created_by = auth.uid()
             )
         );
    END IF;

    -- ASSETS: Enhanced policies with project membership
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'assets') THEN
        CREATE POLICY assets_select_enhanced
        ON public.assets
        FOR SELECT
        TO authenticated
        USING (
            public.is_super_admin()
            OR EXISTS (
                SELECT 1 FROM public.project_members pm
                WHERE pm.project_id = assets.project_id
                AND pm.user_id = auth.uid()
            )
        );

        CREATE POLICY assets_mutate_enhanced
        ON public.assets
        FOR ALL
        TO authenticated
        USING (
            public.is_super_admin()
            OR EXISTS (
                SELECT 1 FROM public.project_members pm
                WHERE pm.project_id = assets.project_id
                AND pm.user_id = auth.uid()
            )
        )
        WITH CHECK (
            public.is_super_admin()
            OR EXISTS (
                SELECT 1 FROM public.project_members pm
                WHERE pm.project_id = assets.project_id
                AND pm.user_id = auth.uid()
            )
        );
    END IF;
END $$;