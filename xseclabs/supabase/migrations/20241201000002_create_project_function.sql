-- ==========================================================
-- CREATE PROJECT WITH MEMBER FUNCTION
-- ==========================================================

CREATE OR REPLACE FUNCTION public.create_project_with_member(
    project_name text,
    project_description text DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER -- Ejecutar con privilegios del propietario de la función
SET search_path = public
AS $$
DECLARE
    new_project_id bigint;
    current_user_id uuid;
    result json;
BEGIN
    -- Obtener el ID del usuario autenticado
    current_user_id := auth.uid();

    -- Verificar que el usuario esté autenticado
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    -- Verificar que el usuario existe en la tabla users
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id_uuid = current_user_id) THEN
        RAISE EXCEPTION 'Usuario no encontrado en la tabla users';
    END IF;

    -- Deshabilitar RLS temporalmente para esta función
    PERFORM set_config('row_security', 'off', true);

    -- Crear el proyecto
    INSERT INTO public.projects (name, description, created_by)
    VALUES (project_name, project_description, current_user_id)
    RETURNING project_id INTO new_project_id;

    -- Agregar al creador como owner del proyecto
    INSERT INTO public.project_members (project_id, user_id, role)
    VALUES (new_project_id, current_user_id, 'owner');

    -- Rehabilitar RLS
    PERFORM set_config('row_security', 'on', true);

    -- Retornar el proyecto creado
    SELECT json_build_object(
        'project_id', p.project_id,
        'name', p.name,
        'description', p.description,
        'created_by', p.created_by,
        'created_at', p.created_at
    ) INTO result
    FROM public.projects p
    WHERE p.project_id = new_project_id;

    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        -- Asegurar que RLS se rehabilite en caso de error
        PERFORM set_config('row_security', 'on', true);
        RAISE;
END;
$$;