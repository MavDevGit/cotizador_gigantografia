import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  Future<String?> createEmpresa(String empresa) async {
    try {
      final response = await client.from('empresas').insert({
        'nombre': empresa,
      }).select('id').single();
      if (response == null || response['id'] == null) return null;
      return response['id'] as String;
    } catch (e) {
      print('❌ Error al crear empresa: $e');
      return null;
    }
  }

  Future<bool> createUsuario({
    required String email,
    required String empresaId,
    required String authUserId,
    required String nombre,
    String rol = 'admin',
  }) async {
    try {
      // Validar que el rol sea válido
      if (rol != 'admin' && rol != 'empleado') {
        print('❌ Rol inválido: $rol. Debe ser "admin" o "empleado"');
        return false;
      }
      
      // Solo enviar los campos requeridos, los demás tienen valores por defecto
      final response = await client.from('usuarios').insert({
        'email': email,
        'empresa_id': empresaId,
        'auth_user_id': authUserId,
        'nombre': nombre,
        'rol': rol,
        // created_at se genera automáticamente
        // archivado tiene valor por defecto false
      });
      // Si no hay excepción, la inserción fue exitosa
      return true;
    } catch (e) {
      print('❌ Error al crear usuario: $e');
      // Log más detallado del error
      if (e.toString().contains('duplicate key')) {
        print('⚠️ Error de clave duplicada - posiblemente el usuario ya existe');
      } else if (e.toString().contains('foreign key')) {
        print('⚠️ Error de clave foránea - verificar que empresa_id existe');
      } else if (e.toString().contains('rol_usuario')) {
        print('⚠️ Error en el tipo de rol - verificar valores del enum rol_usuario');
      }
      return false;
    }
  }
}
