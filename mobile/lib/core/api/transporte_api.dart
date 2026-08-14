import '../models/models.dart';
import 'api_client.dart';

/// Cliente API unificado — equivalente a `frontend/src/shared/api/`.
class TransporteApi {
  TransporteApi({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

  // ─── Consulta pública ───
  Future<List<ViajeDisponible>> buscarViajes({
    required String origen,
    required String destino,
    required String fecha,
  }) async {
    final data = await _api.get<List<dynamic>>(
      '/api/publico/viajes',
      query: {'origen': origen, 'destino': destino, 'fecha': fecha},
    );
    return data.map((e) => ViajeDisponible.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DetalleViaje> detalleViaje(int viajeId) async {
    final data = await _api.get<Map<String, dynamic>>('/api/publico/viajes/$viajeId');
    return DetalleViaje.fromJson(data);
  }

  Future<double> tarifaReferenciaUsd(double monto) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/externo/tarifa-referencia-usd',
      query: {'monto': monto.toString()},
    );
    return (data['equivalenteUsd'] as num).toDouble();
  }

  // ─── Viajes operador ───
  Future<DetalleViaje> detalleViajeOperador(int viajeId, String token) async {
    final data = await _api.get<Map<String, dynamic>>('/api/viajes/$viajeId/detalle-operador', token: token);
    return DetalleViaje.fromJson(data);
  }

  Future<List<ViajeOperador>> viajesPorEmpresa(String token, int empresaId, String fecha, {String? origen}) async {
    final q = {'empresaId': '$empresaId', 'fecha': fecha};
    if (origen != null && origen.isNotEmpty) q['origen'] = origen;
    final data = await _api.get<List<dynamic>>('/api/viajes', query: q, token: token);
    return data.map((e) => ViajeOperador.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ViajeOperador>> viajesMiEmpresa(String token, String fecha, {String? origen}) async {
    final q = {'fecha': fecha};
    if (origen != null && origen.isNotEmpty) q['origen'] = origen;
    final data = await _api.get<List<dynamic>>('/api/viajes/mi-empresa', query: q, token: token);
    return data.map((e) => ViajeOperador.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ViajeOperador> programarViaje(String token, Map<String, dynamic> data) async {
    final res = await _api.post<Map<String, dynamic>>('/api/viajes', body: data, token: token);
    return ViajeOperador.fromJson(res);
  }

  Future<ViajeOperador> cancelarViaje(String token, int id) async {
    final res = await _api.patch<Map<String, dynamic>>('/api/viajes/$id/cancelar', body: {}, token: token);
    return ViajeOperador.fromJson(res);
  }

  Future<ViajeOperador> actualizarViaje(String token, int id, Map<String, dynamic> data) async {
    final res = await _api.put<Map<String, dynamic>>('/api/viajes/$id', body: data, token: token);
    return ViajeOperador.fromJson(res);
  }

  // ─── Ventas ───
  Future<VentaResponse> crearVenta(String token, Map<String, dynamic> data) async {
    final res = await _api.post<Map<String, dynamic>>('/api/ventas', body: data, token: token);
    return VentaResponse.fromJson(res);
  }

  Future<List<ManifiestoPasajero>> manifiestoPasajeros(
    String token, {
    required String fecha,
    int? viajeId,
    int? busId,
    int? empresaId,
  }) async {
    final q = {'fecha': fecha};
    if (viajeId != null) q['viajeId'] = '$viajeId';
    if (busId != null) q['busId'] = '$busId';
    if (empresaId != null) q['empresaId'] = '$empresaId';
    final data = await _api.get<List<dynamic>>('/api/pasajeros/manifiesto', query: q, token: token);
    return data.map((e) => ManifiestoPasajero.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> crearReservaExcepcional(String token, Map<String, dynamic> data) async {
    return await _api.post<Map<String, dynamic>>('/api/reservas-excepcionales', body: data, token: token);
  }

  // ─── Empresas ───
  Future<List<Empresa>> listarEmpresas(String token) async {
    final data = await _api.get<List<dynamic>>('/api/empresas', token: token);
    return data.map((e) => Empresa.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Empresa> miEmpresa(String token) async {
    final data = await _api.get<Map<String, dynamic>>('/api/empresas/mi-empresa', token: token);
    return Empresa.fromJson(data);
  }

  Future<Empresa> obtenerEmpresa(String token, int id) async {
    final data = await _api.get<Map<String, dynamic>>('/api/empresas/$id', token: token);
    return Empresa.fromJson(data);
  }

  Future<Empresa> actualizarEmpresa(String token, int id, Map<String, dynamic> data) async {
    final res = await _api.put<Map<String, dynamic>>('/api/empresas/$id', body: data, token: token);
    return Empresa.fromJson(res);
  }

  Future<Empresa> crearEmpresa(String token, Map<String, dynamic> data) async {
    final res = await _api.post<Map<String, dynamic>>('/api/empresas', body: data, token: token);
    return Empresa.fromJson(res);
  }

  Future<void> desactivarEmpresa(String token, int id) async {
    await _api.patch('/api/empresas/$id/desactivar', body: {}, token: token);
  }

  Future<List<ResumenEmpresa>> resumenPlataforma(String token) async {
    final data = await _api.get<List<dynamic>>('/api/empresas/resumen-plataforma', token: token);
    return data.map((e) => ResumenEmpresa.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DetalleCooperativa> detalleCooperativa(String token, int empresaId) async {
    final data = await _api.get<Map<String, dynamic>>('/api/empresas/$empresaId/detalle-plataforma', token: token);
    return DetalleCooperativa.fromJson(data);
  }

  // ─── Buses ───
  Future<List<Bus>> busesPorEmpresa(String token, int empresaId, {String? sede}) async {
    final q = {'empresaId': '$empresaId'};
    if (sede != null) q['sede'] = sede;
    final data = await _api.get<List<dynamic>>('/api/buses', query: q, token: token);
    return data.map((e) => Bus.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Bus>> busesMiEmpresa(String token, {String? sede}) async {
    final q = sede != null ? {'sede': sede} : null;
    final data = await _api.get<List<dynamic>>('/api/buses/mi-empresa', query: q, token: token);
    return data.map((e) => Bus.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Bus> crearBus(String token, Map<String, dynamic> data) async {
    final res = await _api.post<Map<String, dynamic>>('/api/buses', body: data, token: token);
    return Bus.fromJson(res);
  }

  Future<Bus> actualizarBus(String token, int id, Map<String, dynamic> data) async {
    final res = await _api.put<Map<String, dynamic>>('/api/buses/$id', body: data, token: token);
    return Bus.fromJson(res);
  }

  // ─── Usuarios ───
  Future<UsuarioPerfil> obtenerPerfil(String token) async {
    final data = await _api.get<Map<String, dynamic>>('/api/usuarios/me', token: token);
    return UsuarioPerfil.fromJson(data);
  }

  Future<List<UsuarioPerfil>> listarOperadores(String token, {int? empresaId}) async {
    final q = empresaId != null ? {'empresaId': '$empresaId'} : null;
    final data = await _api.get<List<dynamic>>('/api/usuarios', query: q, token: token);
    return data.map((e) => UsuarioPerfil.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UsuarioPerfil> crearOperador(String token, Map<String, dynamic> data) async {
    final res = await _api.post<Map<String, dynamic>>('/api/usuarios', body: data, token: token);
    return UsuarioPerfil.fromJson(res);
  }

  Future<UsuarioPerfil> actualizarOperador(String token, int id, Map<String, dynamic> data) async {
    final res = await _api.patch<Map<String, dynamic>>('/api/usuarios/$id', body: data, token: token);
    return UsuarioPerfil.fromJson(res);
  }

  // ─── Paradas ───
  Future<List<ParadaRuta>> listarParadas(String token, String origen, String destino, {String? horaSalida}) async {
    final q = {'origen': origen, 'destino': destino};
    if (horaSalida != null) q['horaSalida'] = horaSalida;
    final data = await _api.get<List<dynamic>>('/api/paradas', query: q, token: token);
    return data.map((e) => ParadaRuta.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ParadaRuta> crearParada(String token, Map<String, dynamic> data) async {
    final res = await _api.post<Map<String, dynamic>>('/api/paradas', body: data, token: token);
    return ParadaRuta.fromJson(res);
  }

  Future<ParadaRuta> actualizarParada(String token, int id, Map<String, dynamic> data) async {
    final res = await _api.put<Map<String, dynamic>>('/api/paradas/$id', body: data, token: token);
    return ParadaRuta.fromJson(res);
  }

  Future<void> eliminarParada(String token, int id) async {
    await _api.delete('/api/paradas/$id', token: token);
  }

  // ─── Reportes ───
  Future<List<OcupacionViaje>> reporteOcupacion(String token, String fecha, {int? empresaId}) async {
    final q = {'fecha': fecha};
    if (empresaId != null) q['empresaId'] = '$empresaId';
    final data = await _api.get<List<dynamic>>('/api/reportes/ocupacion', query: q, token: token);
    return data.map((e) => OcupacionViaje.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<IngresosReporte> reporteIngresos(String token, String desde, String hasta, {int? empresaId}) async {
    final q = {'desde': desde, 'hasta': hasta};
    if (empresaId != null) q['empresaId'] = '$empresaId';
    final data = await _api.get<Map<String, dynamic>>('/api/reportes/ingresos', query: q, token: token);
    return IngresosReporte.fromJson(data);
  }
}
