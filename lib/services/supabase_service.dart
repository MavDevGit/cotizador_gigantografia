import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cliente.dart';
import '../models/trabajo.dart';
import '../models/usuario.dart';
import '../models/orden_trabajo.dart';
import '../models/orden_trabajo_item_new.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // === MÉTODOS DE EMPRESAS ===
  
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

  // === MÉTODOS DE USUARIOS ===

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

  Future<Usuario?> getCurrentUser() async {
    try {
      final authUser = client.auth.currentUser;
      if (authUser == null) return null;

      final response = await client
          .from('usuarios')
          .select()
          .eq('auth_user_id', authUser.id)
          .eq('archivado', false)
          .single();

      return Usuario.fromJson(response);
    } catch (e) {
      print('❌ Error al obtener usuario actual: $e');
      return null;
    }
  }

  // === MÉTODOS DE CLIENTES ===

  Future<List<Cliente>> getClientes() async {
    try {
      print('🔍 Obteniendo clientes...');
      
      // Obtener el usuario actual autenticado
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        print('❌ No hay usuario autenticado');
        return [];
      }
      
      print('👤 Usuario autenticado: ${currentUser.email} (${currentUser.id})');
      
      // Primero obtener el usuario de la base de datos para conseguir su empresa_id
      final userResponse = await client
          .from('usuarios')
          .select('empresa_id')
          .eq('auth_user_id', currentUser.id)
          .single();
          
      print('🏢 Datos del usuario: $userResponse');
      
      final empresaId = userResponse['empresa_id'] as String;
      print('🏢 Empresa ID: $empresaId');
      
      final response = await client
          .from('clientes')
          .select()
          .eq('archivado', false)
          .eq('empresa_id', empresaId)  // Filtrar por empresa
          .order('nombre');

      print('📊 Respuesta de clientes: ${response.length} registros encontrados');
      
      final clientes = (response as List)
          .map((json) => Cliente.fromJson(json))
          .toList();
          
      print('✅ Clientes procesados: ${clientes.length}');
      for (var cliente in clientes) {
        print('   - ${cliente.nombre} (${cliente.id})');
      }
      
      return clientes;
    } catch (e) {
      print('❌ Error al obtener clientes: $e');
      return [];
    }
  }

  Future<List<Cliente>> getClientesArchivados() async {
    try {
      print('🔍 Obteniendo clientes archivados...');
      
      // Obtener el usuario actual autenticado
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        print('❌ No hay usuario autenticado');
        return [];
      }
      
      // Obtener el empresa_id del usuario
      final userResponse = await client
          .from('usuarios')
          .select('empresa_id')
          .eq('auth_user_id', currentUser.id)
          .single();
          
      final empresaId = userResponse['empresa_id'] as String;
      
      final response = await client
          .from('clientes')
          .select()
          .eq('archivado', true)
          .eq('empresa_id', empresaId)  // Filtrar por empresa
          .order('nombre');

      return (response as List)
          .map((json) => Cliente.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error al obtener clientes archivados: $e');
      return [];
    }
  }

  Future<bool> addCliente(Cliente cliente) async {
    try {
      await client.from('clientes').insert(cliente.toJson());
      return true;
    } catch (e) {
      print('❌ Error al agregar cliente: $e');
      return false;
    }
  }

  Future<bool> updateCliente(Cliente cliente) async {
    try {
      await client
          .from('clientes')
          .update(cliente.toJson())
          .eq('id', cliente.id);
      return true;
    } catch (e) {
      print('❌ Error al actualizar cliente: $e');
      return false;
    }
  }

  Future<bool> deleteCliente(String clienteId) async {
    try {
      await client
          .from('clientes')
          .update({'archivado': true})
          .eq('id', clienteId);
      return true;
    } catch (e) {
      print('❌ Error al archivar cliente: $e');
      return false;
    }
  }

  Future<bool> restoreCliente(String clienteId) async {
    try {
      await client
          .from('clientes')
          .update({'archivado': false})
          .eq('id', clienteId);
      return true;
    } catch (e) {
      print('❌ Error al restaurar cliente: $e');
      return false;
    }
  }

  // === MÉTODOS DE TRABAJOS ===

  Future<List<Trabajo>> getTrabajos() async {
    try {
      print('🔍 Obteniendo trabajos...');
      
      // Verificar que hay un usuario autenticado
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        print('❌ No hay usuario autenticado');
        return [];
      }

      // Obtener empresa_id del usuario
      final usuarioResponse = await client
          .from('usuarios')
          .select('empresa_id')
          .eq('auth_user_id', currentUser.id)
          .single();

      final empresaId = usuarioResponse['empresa_id'] as String;
      print('👤 Usuario autenticado, empresa_id: $empresaId');

      final response = await client
          .from('trabajos')
          .select()
          .eq('archivado', false)
          .eq('empresa_id', empresaId)
          .order('nombre');

      final trabajos = (response as List)
          .map((json) => Trabajo.fromJson(json))
          .toList();
          
      print('📊 Respuesta de trabajos: ${trabajos.length} registros encontrados');
      print('✅ Trabajos procesados: ${trabajos.length}');
      for (var trabajo in trabajos) {
        print('   - ${trabajo.nombre} (${trabajo.id})');
      }

      return trabajos;
    } catch (e) {
      print('❌ Error al obtener trabajos: $e');
      return [];
    }
  }

  Future<List<Trabajo>> getTrabajosArchivados() async {
    try {
      print('🔍 Obteniendo trabajos archivados...');
      
      // Verificar que hay un usuario autenticado
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        print('❌ No hay usuario autenticado');
        return [];
      }

      // Obtener empresa_id del usuario
      final usuarioResponse = await client
          .from('usuarios')
          .select('empresa_id')
          .eq('auth_user_id', currentUser.id)
          .single();

      final empresaId = usuarioResponse['empresa_id'] as String;
      print('👤 Usuario autenticado, empresa_id: $empresaId');

      final response = await client
          .from('trabajos')
          .select()
          .eq('archivado', true)
          .eq('empresa_id', empresaId)
          .order('nombre');

      final trabajosArchivados = (response as List)
          .map((json) => Trabajo.fromJson(json))
          .toList();
          
      print('📊 Respuesta de trabajos archivados: ${trabajosArchivados.length} registros encontrados');

      return trabajosArchivados;
    } catch (e) {
      print('❌ Error al obtener trabajos archivados: $e');
      return [];
    }
  }

  Future<bool> addTrabajo(Trabajo trabajo) async {
    try {
      await client.from('trabajos').insert(trabajo.toJson());
      return true;
    } catch (e) {
      print('❌ Error al agregar trabajo: $e');
      return false;
    }
  }

  Future<bool> updateTrabajo(Trabajo trabajo) async {
    try {
      await client
          .from('trabajos')
          .update(trabajo.toJson())
          .eq('id', trabajo.id);
      return true;
    } catch (e) {
      print('❌ Error al actualizar trabajo: $e');
      return false;
    }
  }

  Future<bool> deleteTrabajo(String trabajoId) async {
    try {
      await client
          .from('trabajos')
          .update({'archivado': true})
          .eq('id', trabajoId);
      return true;
    } catch (e) {
      print('❌ Error al archivar trabajo: $e');
      return false;
    }
  }

  Future<bool> restoreTrabajo(String trabajoId) async {
    try {
      await client
          .from('trabajos')
          .update({'archivado': false})
          .eq('id', trabajoId);
      return true;
    } catch (e) {
      print('❌ Error al restaurar trabajo: $e');
      return false;
    }
  }

  // === MÉTODOS DE ÓRDENES DE TRABAJO ===

  Future<List<OrdenTrabajo>> getOrdenes() async {
    try {
      print('🔍 Obteniendo órdenes de trabajo...');
      
      // Verificar que hay un usuario autenticado
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        print('❌ No hay usuario autenticado');
        return [];
      }
      
      print('👤 Usuario autenticado: ${currentUser.email} (${currentUser.id})');

      // Obtener órdenes con clientes (RLS se encargará del filtrado por empresa)
      final response = await client
          .from('ordenes_trabajo')
          .select('''
            *,
            clientes!inner(*)
          ''')
          .order('created_at', ascending: false);

      print('📊 Respuesta de órdenes: ${response.length} registros encontrados');
      
      List<OrdenTrabajo> ordenes = [];

      for (var ordenData in response) {
        try {
          // Obtener ítems de la orden
          final itemsResponse = await client
              .from('orden_trabajo_items')
              .select()
              .eq('orden_id', ordenData['id']);

          final items = (itemsResponse as List)
              .map((itemJson) => OrdenTrabajoItem.fromJson(itemJson))
              .toList();

          // Crear el objeto orden con cliente e ítems
          final orden = OrdenTrabajo.fromJson({
            ...ordenData,
            'cliente': ordenData['clientes'],
            'items': items.map((item) => item.toJson()).toList(),
          });

          ordenes.add(orden);
          print('   ✅ Orden procesada: ${orden.id} - Cliente: ${orden.cliente.nombre}');
        } catch (e) {
          print('   ❌ Error procesando orden ${ordenData['id']}: $e');
        }
      }

      print('✅ Total órdenes procesadas: ${ordenes.length}');
      return ordenes;
    } catch (e) {
      print('❌ Error al obtener órdenes: $e');
      return [];
    }
  }

  Future<String?> addOrden(OrdenTrabajo orden) async {
    try {
      // Preparar datos para la función RPC
      final itemsJson = orden.items.map((item) => {
        'trabajo_nombre': item.trabajoNombre,
        'trabajo_precio_m2': item.trabajoPrecioM2,
        'ancho': item.ancho,
        'alto': item.alto,
        'cantidad': item.cantidad,
        'adicional': item.adicional,
      }).toList();

      // Usar la función RPC para crear la orden con sus ítems
      final response = await client.rpc('crear_orden_con_items', params: {
        'p_cliente_id': orden.cliente.id,
        'p_adelanto': orden.adelanto,
        'p_total_personalizado': orden.totalPersonalizado,
        'p_notas': orden.notas,
        'p_estado': orden.estado,
        'p_fecha_entrega': orden.fechaEntrega.toIso8601String().split('T')[0],
        'p_hora_entrega': '${orden.horaEntrega.hour.toString().padLeft(2, '0')}:${orden.horaEntrega.minute.toString().padLeft(2, '0')}:00',
        'p_items': itemsJson,
      });

      return response as String?;
    } catch (e) {
      print('❌ Error al agregar orden: $e');
      return null;
    }
  }

  Future<bool> updateOrden(OrdenTrabajo orden) async {
    try {
      // Actualizar datos básicos de la orden
      await client
          .from('ordenes_trabajo')
          .update(orden.toJson())
          .eq('id', orden.id);

      // Eliminar ítems existentes
      await client
          .from('orden_trabajo_items')
          .delete()
          .eq('orden_id', orden.id);

      // Insertar nuevos ítems
      if (orden.items.isNotEmpty) {
        final itemsData = orden.items.map((item) => item.toJson(includeId: false)).toList();
        await client.from('orden_trabajo_items').insert(itemsData);
      }

      return true;
    } catch (e) {
      print('❌ Error al actualizar orden: $e');
      return false;
    }
  }

  Future<bool> deleteOrden(String ordenId) async {
    try {
      // Los ítems se eliminarán automáticamente por CASCADE
      await client
          .from('ordenes_trabajo')
          .delete()
          .eq('id', ordenId);
      return true;
    } catch (e) {
      print('❌ Error al eliminar orden: $e');
      return false;
    }
  }

  Future<bool> updateOrdenEstado(String ordenId, String nuevoEstado) async {
    try {
      await client
          .from('ordenes_trabajo')
          .update({'estado': nuevoEstado})
          .eq('id', ordenId);
      return true;
    } catch (e) {
      print('❌ Error al actualizar estado de orden: $e');
      return false;
    }
  }

  // === MÉTODOS AUXILIARES ===

  Future<List<OrdenTrabajo>> getOrdenesPorCliente(String clienteId) async {
    try {
      final todasLasOrdenes = await getOrdenes();
      return todasLasOrdenes.where((orden) => orden.cliente.id == clienteId).toList();
    } catch (e) {
      print('❌ Error al obtener órdenes por cliente: $e');
      return [];
    }
  }

  Future<Map<String, int>> getEstadisticasOrdenes() async {
    try {
      print('📊 Obteniendo estadísticas de órdenes...');
      
      // Usar la función RPC para obtener estadísticas
      final response = await client.rpc('get_order_statistics');
      
      final estadisticas = <String, int>{};
      
      for (var row in response) {
        estadisticas[row['estado']] = row['cantidad'];
      }
      
      print('✅ Estadísticas obtenidas: $estadisticas');
      return estadisticas;
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      // Fallback: obtener estadísticas manualmente
      try {
        final ordenes = await getOrdenes();
        final estadisticas = <String, int>{};
        
        for (var orden in ordenes) {
          estadisticas[orden.estado] = (estadisticas[orden.estado] ?? 0) + 1;
        }
        
        return estadisticas;
      } catch (e2) {
        print('❌ Error en fallback de estadísticas: $e2');
        return {};
      }
    }
  }

  // Nuevo método para obtener datos del dashboard
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      print('📊 Obteniendo datos del dashboard...');
      
      final response = await client.rpc('get_dashboard_data');
      
      if (response != null) {
        print('✅ Datos del dashboard obtenidos: $response');
        return Map<String, dynamic>.from(response);
      }
      
      return {};
    } catch (e) {
      print('❌ Error al obtener datos del dashboard: $e');
      return {};
    }
  }
}
