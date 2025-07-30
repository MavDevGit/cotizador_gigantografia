-- Script para corregir el tipo de enum de rol en la tabla usuarios
-- Este script debe ejecutarse en el panel SQL de Supabase

-- PASO 1: Verificar el estado actual de la tabla
SELECT data_type, udt_name, column_name 
FROM information_schema.columns 
WHERE table_name = 'usuarios' AND column_name IN ('rol', 'rol_temp')
ORDER BY column_name;

-- Ver qué valores existen actualmente en la tabla
SELECT DISTINCT rol, COUNT(*) as cantidad
FROM usuarios 
GROUP BY rol
ORDER BY rol;

-- PASO 2: Limpiar cualquier intento anterior
-- Eliminar la columna temporal si existe
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'usuarios' AND column_name = 'rol_temp') THEN
        ALTER TABLE usuarios DROP COLUMN rol_temp;
        RAISE NOTICE 'Columna rol_temp eliminada';
    ELSE
        RAISE NOTICE 'Columna rol_temp no existe';
    END IF;
END $$;

-- PASO 3: Verificar/crear el tipo enum
DO $$ 
BEGIN
    -- Verificar si el tipo ya existe con el nombre actual
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'rol_usuario') THEN
        -- Si existe, verificar sus valores
        RAISE NOTICE 'El tipo rol_usuario ya existe';
    ELSE
        -- Si no existe, crearlo
        CREATE TYPE rol_usuario AS ENUM ('admin', 'empleado');
        RAISE NOTICE 'Tipo rol_usuario creado';
    END IF;
END $$;

-- PASO 4: Alterar la tabla para usar el enum correcto
-- Agregar una columna temporal (usar el tipo correcto)
ALTER TABLE usuarios ADD COLUMN rol_temp rol_usuario;

-- PASO 5: Copiar los valores, mapeando a los valores correctos del enum
-- Convertir todo a minúsculas y mapear correctamente
UPDATE usuarios 
SET rol_temp = 
    (CASE 
        WHEN LOWER(rol::text) = 'admin' OR LOWER(rol::text) = 'administrador' THEN 'admin'
        WHEN LOWER(rol::text) = 'empleado' OR LOWER(rol::text) = 'usuario' THEN 'empleado'
        ELSE 'empleado' -- valor por defecto
    END)::rol_usuario;

-- PASO 6: Eliminar políticas que dependen de la columna rol
DROP POLICY IF EXISTS trabajos_insert_policy ON trabajos;
DROP POLICY IF EXISTS trabajos_update_policy ON trabajos;
DROP POLICY IF EXISTS trabajos_delete_policy ON trabajos;

-- PASO 7: Eliminar la columna original
ALTER TABLE usuarios DROP COLUMN rol;

-- PASO 8: Renombrar la columna temporal
ALTER TABLE usuarios RENAME COLUMN rol_temp TO rol;

-- PASO 9: Establecer NOT NULL y valor por defecto
ALTER TABLE usuarios ALTER COLUMN rol SET NOT NULL;
ALTER TABLE usuarios ALTER COLUMN rol SET DEFAULT 'empleado'::rol_usuario;

-- PASO 10: Recrear las políticas RLS (ajustar según tus necesidades)
-- Estas son políticas básicas, puedes ajustarlas según tu lógica de negocio
CREATE POLICY trabajos_insert_policy ON trabajos
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE usuarios.auth_user_id = auth.uid() 
            AND usuarios.empresa_id = trabajos.empresa_id
        )
    );

CREATE POLICY trabajos_update_policy ON trabajos
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE usuarios.auth_user_id = auth.uid() 
            AND usuarios.empresa_id = trabajos.empresa_id
        )
    );

CREATE POLICY trabajos_delete_policy ON trabajos
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE usuarios.auth_user_id = auth.uid() 
            AND usuarios.empresa_id = trabajos.empresa_id
            AND usuarios.rol = 'admin'
        )
    );

-- PASO 11: Verificar el resultado final
SELECT data_type, udt_name, column_name, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'usuarios' AND column_name = 'rol';

-- Mostrar algunos registros para verificar
SELECT id, email, nombre, rol FROM usuarios LIMIT 5;
