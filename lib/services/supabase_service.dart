import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  Future<String?> createEmpresa(String empresa) async {
    final response = await client.from('empresas').insert({
      'nombre': empresa,
    }).select('id').single();
    if (response == null || response['id'] == null) return null;
    return response['id'] as String;
  }

  Future<bool> createUsuario({
    required String email,
    required String empresaId,
    required String authUserId,
    String rol = 'admin',
  }) async {
    final response = await client.from('usuarios').insert({
      'email': email,
      'empresa_id': empresaId,
      'auth_user_id': authUserId,
      'rol': rol,
    });
    if (response == null) return true; // Si no hay error y no se solicitó retorno, se asume éxito
    if (response.error != null) return false;
    return true;
  }
}
