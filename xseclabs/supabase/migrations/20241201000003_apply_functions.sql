-- Apply functions.sql to ensure create_project_with_member is available
-- Función para crear un proyecto con su miembro owner automáticamente
-- Esta función se ejecuta con privilegios elevados para evitar problemas de RLS
create or replace function public.create_project_with_member(
    project_name text,
    project_description text default null
)
returns json
language plpgsql
security definer -- Ejecutar con privilegios del propietario de la función
set search_path = public
as $$
declare
    new_project_id integer;
    current_user_id uuid;
    result json;
begin
    -- Obtener el ID del usuario autenticado
    current_user_id := auth.uid();
    
    -- Verificar que el usuario esté autenticado
    if current_user_id is null then
        raise exception 'Usuario no autenticado';
    end if;
    
    -- Verificar que el usuario existe en la tabla users
    if not exists (select 1 from public.users where id_uuid = current_user_id) then
        raise exception 'Usuario no encontrado en la tabla users';
    end if;
    
    -- Deshabilitar RLS temporalmente para esta función
    perform set_config('row_security', 'off', true);
    
    -- Crear el proyecto
    insert into public.projects (name, description, created_by)
    values (project_name, project_description, current_user_id)
    returning project_id into new_project_id;
    
    -- Agregar al creador como owner del proyecto
    insert into public.project_members (project_id, user_id, role)
    values (new_project_id, current_user_id, 'owner');
    
    -- Rehabilitar RLS
    perform set_config('row_security', 'on', true);
    
    -- Retornar el proyecto creado
    select json_build_object(
        'project_id', p.project_id,
        'name', p.name,
        'description', p.description,
        'created_by', p.created_by,
        'created_at', p.created_at
    ) into result
    from public.projects p
    where p.project_id = new_project_id;
    
    return result;
exception
    when others then
        -- Asegurar que RLS se rehabilite en caso de error
        perform set_config('row_security', 'on', true);
        raise;
end;
$$;

-- Otorgar permisos de ejecución a usuarios autenticados
grant execute on function public.create_project_with_member(text, text) to authenticated;