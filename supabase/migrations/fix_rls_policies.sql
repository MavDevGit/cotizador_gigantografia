-- Fix RLS Policies - Eliminar recursión infinita
-- 30 Julio 2025

-- Paso 1: Eliminar todas las políticas existentes de usuarios que causan recursión
DROP POLICY IF EXISTS "usuarios_select_policy" ON usuarios;
DROP POLICY IF EXISTS "usuarios_insert_policy" ON usuarios;
DROP POLICY IF EXISTS "usuarios_update_policy" ON usuarios;
DROP POLICY IF EXISTS "usuarios_delete_policy" ON usuarios;

-- Paso 2: Crear políticas RLS simples y seguras para usuarios
-- Política de SELECT: Los usuarios pueden ver sus propios datos
CREATE POLICY "usuarios_select_own" ON usuarios
    FOR SELECT
    USING (auth.uid() = auth_user_id);

-- Política de INSERT: Solo usuarios autenticados pueden crear registros
CREATE POLICY "usuarios_insert_authenticated" ON usuarios
    FOR INSERT
    WITH CHECK (auth.uid() = auth_user_id);

-- Política de UPDATE: Los usuarios pueden actualizar sus propios datos
CREATE POLICY "usuarios_update_own" ON usuarios
    FOR UPDATE
    USING (auth.uid() = auth_user_id)
    WITH CHECK (auth.uid() = auth_user_id);

-- Política de DELETE: Los usuarios pueden eliminar sus propios datos
CREATE POLICY "usuarios_delete_own" ON usuarios
    FOR DELETE
    USING (auth.uid() = auth_user_id);

-- Paso 3: Verificar políticas de empresas también
DROP POLICY IF EXISTS "empresas_select_policy" ON empresas;
DROP POLICY IF EXISTS "empresas_insert_policy" ON empresas;
DROP POLICY IF EXISTS "empresas_update_policy" ON empresas;
DROP POLICY IF EXISTS "empresas_delete_policy" ON empresas;

-- Políticas para empresas
CREATE POLICY "empresas_select_by_users" ON empresas
    FOR SELECT
    USING (
        id IN (
            SELECT empresa_id 
            FROM usuarios 
            WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "empresas_insert_authenticated" ON empresas
    FOR INSERT
    WITH CHECK (true); -- Cualquier usuario autenticado puede crear empresa

CREATE POLICY "empresas_update_by_users" ON empresas
    FOR UPDATE
    USING (
        id IN (
            SELECT empresa_id 
            FROM usuarios 
            WHERE auth_user_id = auth.uid()
        )
    );

-- Paso 4: Asegurar que RLS esté habilitado
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE empresas ENABLE ROW LEVEL SECURITY;

-- Paso 5: Verificar que las políticas se crearon correctamente
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE tablename IN ('usuarios', 'empresas')
ORDER BY tablename, policyname;
