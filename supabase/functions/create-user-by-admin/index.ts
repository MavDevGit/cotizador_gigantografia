import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

Deno.serve(async (req) => {
  // Manejo de la solicitud pre-vuelo (preflight) para CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Extraer los datos del cuerpo de la solicitud
    const { email, password, nombre, rol, empresa_id } = await req.json()

    // 2. Validación explícita de los datos de entrada (lo mejor de tu versión)
    if (!email || !password || !nombre || !rol || !empresa_id) {
      return new Response(JSON.stringify({ error: 'Faltan campos obligatorios en la solicitud.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }
    if (password.length < 6) {
        return new Response(JSON.stringify({ error: 'La contraseña debe tener al menos 6 caracteres.' }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
        })
    }

    // 3. Crear un cliente de Supabase con privilegios de administrador
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // 4. Llamar a la API de admin para crear el usuario (lo mejor de la versión del artefacto)
    // Pasamos los datos del perfil en 'user_metadata' para que el trigger los utilice.
    const { data: { user }, error } = await supabaseAdmin.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true, // Marcamos el email como confirmado inmediatamente
      user_metadata: {
        nombre: nombre,
        rol: rol,
        empresa_id: empresa_id
      },
    })

    if (error) {
      // Si Supabase devuelve un error (ej: email ya existe), lo reenviamos al cliente.
      console.error('Error al crear usuario en Supabase Auth:', error.message)
      return new Response(JSON.stringify({ error: error.message }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400, // Usamos 400 para errores de cliente (ej: email duplicado)
      })
    }

    // Si todo fue exitoso, el trigger ya habrá creado el perfil en `public.usuarios`.
    return new Response(JSON.stringify({ user }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    console.error('Error inesperado en la función:', error.message)
    return new Response(JSON.stringify({ error: 'Error interno del servidor.' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
