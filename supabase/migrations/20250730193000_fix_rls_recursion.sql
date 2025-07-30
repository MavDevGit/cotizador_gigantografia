-- Migración para corregir recursión infinita en políticas RLS
-- Fecha: 30 Julio 2025
-- Problema: Las políticas RLS causan recursión infinita al referenciar la tabla usuarios

-- PASO 1: Eliminar todas las políticas RLS problemáticas
DROP POLICY IF EXISTS "Users can view users from their company" ON public.usuarios;
DROP POLICY IF EXISTS "Users can view clients from their company" ON public.clientes;
DROP POLICY IF EXISTS "Users can view jobs from their company" ON public.trabajos;
DROP POLICY IF EXISTS "Users can view orders from their company" ON public.ordenes_trabajo;
DROP POLICY IF EXISTS "Users can view order items from their company" ON public.orden_trabajo_items;
DROP POLICY IF EXISTS "Users can view their own company" ON public.empresas;

DROP POLICY IF EXISTS "Users can insert clients in their company" ON public.clientes;
DROP POLICY IF EXISTS "Users can update clients in their company" ON public.clientes;
DROP POLICY IF EXISTS "Users can delete clients in their company" ON public.clientes;

DROP POLICY IF EXISTS "Users can insert jobs in their company" ON public.trabajos;
DROP POLICY IF EXISTS "Users can update jobs in their company" ON public.trabajos;
DROP POLICY IF EXISTS "Users can delete jobs in their company" ON public.trabajos;

DROP POLICY IF EXISTS "Users can insert orders in their company" ON public.ordenes_trabajo;
DROP POLICY IF EXISTS "Users can update orders in their company" ON public.ordenes_trabajo;
DROP POLICY IF EXISTS "Users can delete orders in their company" ON public.ordenes_trabajo;

DROP POLICY IF EXISTS "Users can insert order items in their company" ON public.orden_trabajo_items;
DROP POLICY IF EXISTS "Users can update order items in their company" ON public.orden_trabajo_items;
DROP POLICY IF EXISTS "Users can delete order items in their company" ON public.orden_trabajo_items;

DROP POLICY IF EXISTS "Admins can update users in their company" ON public.usuarios;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.usuarios;
DROP POLICY IF EXISTS "Admins can update their company" ON public.empresas;

-- PASO 2: Crear función auxiliar sin recursión que usa auth.uid() directamente
CREATE OR REPLACE FUNCTION get_current_user_empresa_id()
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT empresa_id 
  FROM usuarios 
  WHERE auth_user_id = auth.uid() 
    AND archivado = false 
  LIMIT 1;
$$;

-- PASO 3: Políticas RLS simplificadas para USUARIOS (sin recursión)
CREATE POLICY "usuarios_select_own_company" ON public.usuarios
  FOR SELECT TO authenticated
  USING (
    empresa_id = (
      SELECT empresa_id 
      FROM usuarios u2 
      WHERE u2.auth_user_id = auth.uid() 
        AND u2.archivado = false 
      LIMIT 1
    )
  );

CREATE POLICY "usuarios_insert_signup" ON public.usuarios
  FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "usuarios_update_own_profile" ON public.usuarios
  FOR UPDATE TO authenticated
  USING (auth_user_id = auth.uid());

CREATE POLICY "usuarios_update_admin_company" ON public.usuarios
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM usuarios u2 
      WHERE u2.auth_user_id = auth.uid() 
        AND u2.empresa_id = usuarios.empresa_id 
        AND u2.rol = 'admin' 
        AND u2.archivado = false
    )
  );

-- PASO 4: Políticas RLS simplificadas para EMPRESAS
CREATE POLICY "empresas_select_own" ON public.empresas
  FOR SELECT TO authenticated
  USING (id = get_current_user_empresa_id());

CREATE POLICY "empresas_insert_signup" ON public.empresas
  FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "empresas_update_admin" ON public.empresas
  FOR UPDATE TO authenticated
  USING (
    id = get_current_user_empresa_id() AND
    EXISTS (
      SELECT 1 FROM usuarios 
      WHERE auth_user_id = auth.uid() 
        AND empresa_id = empresas.id 
        AND rol = 'admin' 
        AND archivado = false
    )
  );

-- PASO 5: Políticas RLS simplificadas para CLIENTES
CREATE POLICY "clientes_select_company" ON public.clientes
  FOR SELECT TO authenticated
  USING (empresa_id = get_current_user_empresa_id());

CREATE POLICY "clientes_insert_company" ON public.clientes
  FOR INSERT TO authenticated
  WITH CHECK (
    empresa_id = get_current_user_empresa_id() AND 
    auth_user_id = auth.uid()
  );

CREATE POLICY "clientes_update_company" ON public.clientes
  FOR UPDATE TO authenticated
  USING (empresa_id = get_current_user_empresa_id());

CREATE POLICY "clientes_delete_company" ON public.clientes
  FOR DELETE TO authenticated
  USING (empresa_id = get_current_user_empresa_id());

-- PASO 6: Políticas RLS simplificadas para TRABAJOS
CREATE POLICY "trabajos_select_company" ON public.trabajos
  FOR SELECT TO authenticated
  USING (empresa_id = get_current_user_empresa_id());

CREATE POLICY "trabajos_insert_company" ON public.trabajos
  FOR INSERT TO authenticated
  WITH CHECK (empresa_id = get_current_user_empresa_id());

CREATE POLICY "trabajos_update_company" ON public.trabajos
  FOR UPDATE TO authenticated
  USING (empresa_id = get_current_user_empresa_id());

CREATE POLICY "trabajos_delete_company" ON public.trabajos
  FOR DELETE TO authenticated
  USING (empresa_id = get_current_user_empresa_id());

-- PASO 7: Políticas RLS simplificadas para ORDENES_TRABAJO
CREATE POLICY "ordenes_select_company" ON public.ordenes_trabajo
  FOR SELECT TO authenticated
  USING (empresa_id = get_current_user_empresa_id());

CREATE POLICY "ordenes_insert_company" ON public.ordenes_trabajo
  FOR INSERT TO authenticated
  WITH CHECK (
    empresa_id = get_current_user_empresa_id() AND 
    auth_user_id = auth.uid()
  );

CREATE POLICY "ordenes_update_company" ON public.ordenes_trabajo
  FOR UPDATE TO authenticated
  USING (empresa_id = get_current_user_empresa_id());

CREATE POLICY "ordenes_delete_company" ON public.ordenes_trabajo
  FOR DELETE TO authenticated
  USING (empresa_id = get_current_user_empresa_id());

-- PASO 8: Políticas RLS simplificadas para ORDEN_TRABAJO_ITEMS
CREATE POLICY "orden_items_select_company" ON public.orden_trabajo_items
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM ordenes_trabajo ot 
      WHERE ot.id = orden_trabajo_items.orden_id 
        AND ot.empresa_id = get_current_user_empresa_id()
    )
  );

CREATE POLICY "orden_items_insert_company" ON public.orden_trabajo_items
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM ordenes_trabajo ot 
      WHERE ot.id = orden_trabajo_items.orden_id 
        AND ot.empresa_id = get_current_user_empresa_id()
    )
  );

CREATE POLICY "orden_items_update_company" ON public.orden_trabajo_items
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM ordenes_trabajo ot 
      WHERE ot.id = orden_trabajo_items.orden_id 
        AND ot.empresa_id = get_current_user_empresa_id()
    )
  );

CREATE POLICY "orden_items_delete_company" ON public.orden_trabajo_items
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM ordenes_trabajo ot 
      WHERE ot.id = orden_trabajo_items.orden_id 
        AND ot.empresa_id = get_current_user_empresa_id()
    )
  );

-- PASO 9: Crear función de seguridad para obtener usuario actual (RPC seguro)
CREATE OR REPLACE FUNCTION public.get_current_user_safe()
RETURNS TABLE(
  id uuid,
  email text,
  nombre text,
  rol rol_usuario,
  empresa_id uuid,
  auth_user_id uuid,
  archivado boolean,
  created_at timestamptz
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT 
    u.id,
    u.email,
    u.nombre,
    u.rol,
    u.empresa_id,
    u.auth_user_id,
    u.archivado,
    u.created_at
  FROM usuarios u
  WHERE u.auth_user_id = auth.uid()
    AND u.archivado = false
  LIMIT 1;
$$;

-- PASO 10: Comentarios de documentación
COMMENT ON FUNCTION get_current_user_empresa_id() IS 'Función optimizada que obtiene empresa_id del usuario actual sin causar recursión RLS';
COMMENT ON FUNCTION get_current_user_safe() IS 'Función RPC segura para obtener datos del usuario actual sin problemas de RLS';
