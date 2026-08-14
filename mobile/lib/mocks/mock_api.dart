import '../core/api/api_client.dart';
import '../core/utils/formato.dart';
import 'mock_data.dart';
import 'mock_demo_profile.dart';

Future<void> _delay() => Future<void>.delayed(const Duration(milliseconds: mockDelayMs));

int? _matchId(String pathname, String prefix) {
  if (!pathname.startsWith(prefix)) return null;
  final rest = pathname.substring(prefix.length);
  final idStr = rest.split('/').first;
  return int.tryParse(idStr);
}

List<Map<String, dynamic>> _filterViajes({
  required String fecha,
  int? empresaId,
  String? origen,
}) {
  var list = mockViajesOperadorJson(fecha);
  if (empresaId != null) {
    list = list.where((v) => v['empresaId'] == empresaId).toList();
  }
  if (origen != null && origen.isNotEmpty) {
    list = list.where((v) => v['origen'] == origen).toList();
  }
  return list;
}

List<Map<String, dynamic>> _filterBuses({int? empresaId, String? sede}) {
  var list = mockBusesJson.cast<Map<String, dynamic>>().toList();
  if (empresaId != null) {
    list = list.where((b) => b['empresaId'] == empresaId).toList();
  }
  if (sede != null && sede.isNotEmpty) {
    list = list.where((b) => b['sede'] == sede).toList();
  }
  return list;
}

Future<dynamic> handleMockRequest(
  String method,
  String path, {
  Map<String, String>? query,
  Object? body,
}) async {
  await _delay();

  final q = query ?? {};
  final bodyMap = switch (body) {
    Map<String, dynamic> m => m,
    Map m => Map<String, dynamic>.from(m),
    _ => null,
  };
  final pathname = path.split('?').first;

  // Perfil / usuarios
  if (pathname == '/api/usuarios/me') return mockPerfilForProfile(MockSession.profile);

  if (pathname == '/api/usuarios' && method == 'GET') {
    final empresaId = q['empresaId'];
    if (empresaId != null) {
      return mockOperadoresJson.where((o) => o['empresaId'] == int.parse(empresaId)).toList();
    }
    return mockOperadoresJson;
  }

  if (pathname == '/api/usuarios' && method == 'POST') {
    return {
      'id': 99,
      'empresaId': bodyMap?['empresaId'] ?? 1,
      'empresaNombre': 'Wendelyn Transporte',
      'nombreUsuario': bodyMap?['nombreUsuario'] ?? 'nuevo.operador',
      'emailLogin': bodyMap?['email'] ?? 'nuevo@demo.com',
      'nombreCompleto': bodyMap?['nombreCompleto'] ?? 'Operador Demo',
      'sede': bodyMap?['sede'] ?? 'Bluefields',
      'activo': true,
      'roles': bodyMap?['roles'] ?? ['CAJERO'],
    };
  }

  final usuarioId = _matchId(pathname, '/api/usuarios/');
  if (usuarioId != null && method == 'PATCH') {
    final user = mockOperadoresJson.cast<Map<String, dynamic>>().firstWhere(
          (o) => o['id'] == usuarioId,
          orElse: () => mockPerfilForProfile(MockSession.profile),
        );
    return {...user, ...?bodyMap};
  }

  // Empresas
  if (pathname == '/api/empresas' && method == 'GET') return mockEmpresasJson;

  if (pathname == '/api/empresas' && method == 'POST') {
    return {
      'id': mockEmpresasJson.length + 1,
      'nombre': bodyMap?['nombre'] ?? 'Cooperativa Demo',
      'telefono': bodyMap?['telefono'],
      'correo': bodyMap?['correo'],
      'tarifaEquipajeExtra': bodyMap?['tarifaEquipajeExtra'] ?? 150.0,
      'logoUrl': bodyMap?['logoUrl'],
      'activo': true,
    };
  }

  if (pathname == '/api/empresas/mi-empresa') return mockEmpresasJson.first;

  if (pathname == '/api/empresas/resumen-plataforma') return mockResumenPlataformaJson;

  final empresaId = _matchId(pathname, '/api/empresas/');
  if (empresaId != null && pathname.endsWith('/detalle-plataforma')) {
    return mockDetalleCooperativaJson(empresaId);
  }

  if (empresaId != null && pathname.endsWith('/desactivar') && method == 'PATCH') {
    return {'message': 'Cooperativa desactivada (demo)', 'id': '$empresaId'};
  }

  if (empresaId != null && method == 'PUT') {
    final emp = mockEmpresasJson.cast<Map<String, dynamic>>().firstWhere(
          (e) => e['id'] == empresaId,
          orElse: () => mockEmpresasJson.first,
        );
    return {...emp, ...?bodyMap};
  }

  if (empresaId != null) {
    for (final e in mockEmpresasJson) {
      if (e['id'] == empresaId) return e;
    }
  }

  // Buses
  if (pathname == '/api/buses/mi-empresa') {
    return _filterBuses(empresaId: 1, sede: q['sede']);
  }

  if (pathname == '/api/buses' && method == 'GET') {
    final empId = q['empresaId'] != null ? int.parse(q['empresaId']!) : null;
    return _filterBuses(empresaId: empId, sede: q['sede']);
  }

  if (pathname == '/api/buses' && method == 'POST') {
    return {
      'id': mockBusesJson.length + 1,
      'empresaId': bodyMap?['empresaId'] ?? 1,
      'numeroInterno': bodyMap?['numeroInterno'] ?? 'D-01',
      'placa': bodyMap?['placa'] ?? 'NI-9999',
      'capacidad': bodyMap?['capacidad'] ?? 50,
      'filas': 13,
      'activo': true,
      'fotoUrl': bodyMap?['fotoUrl'],
      'sede': bodyMap?['sede'] ?? 'Bluefields',
      'asientos': _buildAsientosBusJson(mockBusesJson.length + 1),
    };
  }

  final busId = _matchId(pathname, '/api/buses/');
  if (busId != null && pathname.contains('/asientos/') && method == 'PUT') {
    final asientoId = _matchId(pathname, '/asientos/');
    return {
      'id': asientoId,
      'numero': bodyMap?['numero'] ?? 1,
      'fila': bodyMap?['fila'] ?? 1,
      'posicion': bodyMap?['posicion'] ?? 'VENTANA',
    };
  }

  if (busId != null && method == 'PUT') {
    final bus = mockBusesJson.cast<Map<String, dynamic>>().firstWhere(
          (b) => b['id'] == busId,
          orElse: () => mockBusesJson.first,
        );
    return {...bus, ...?bodyMap};
  }

  if (busId != null) {
    for (final b in mockBusesJson) {
      if (b['id'] == busId) return b;
    }
  }

  // Viajes
  if (pathname == '/api/viajes/mi-empresa') {
    return _filterViajes(
      fecha: q['fecha'] ?? fechaHoyIso(),
      empresaId: 1,
      origen: q['origen'],
    );
  }

  if (pathname == '/api/viajes' && method == 'GET') {
    return _filterViajes(
      fecha: q['fecha'] ?? fechaHoyIso(),
      empresaId: q['empresaId'] != null ? int.parse(q['empresaId']!) : null,
      origen: q['origen'],
    );
  }

  if (pathname == '/api/viajes' && method == 'POST') {
    final fecha = bodyMap?['fecha']?.toString() ?? fechaHoyIso();
    final empId = bodyMap?['empresaId'] as int? ?? 1;
    final busIdVal = bodyMap?['busId'] as int? ?? 1;
    Map<String, dynamic>? bus;
    for (final b in mockBusesJson) {
      if (b['id'] == busIdVal) {
        bus = b;
        break;
      }
    }
    Map<String, dynamic>? emp;
    for (final e in mockEmpresasJson) {
      if (e['id'] == empId) {
        emp = e;
        break;
      }
    }
    return {
      'id': 900 + mockViajesOperadorJson(fecha).length,
      'empresaId': empId,
      'empresaNombre': emp?['nombre'] ?? 'Wendelyn Transporte',
      'busId': busIdVal,
      'busNumeroInterno': bus?['numeroInterno'] ?? 'W-01',
      'origen': bodyMap?['origen'] ?? 'Bluefields',
      'destino': bodyMap?['destino'] ?? 'Managua',
      'fecha': fecha,
      'horaSalida': bodyMap?['horaSalida'] ?? '08:00:00',
      'tarifa': bodyMap?['tarifa'] ?? 350.0,
      'tarifaEquipajeExtra': bodyMap?['tarifaEquipajeExtra'] ?? 150.0,
      'estado': 'PROGRAMADO',
      'asientosDisponibles': 50,
    };
  }

  final viajeId = _matchId(pathname, '/api/viajes/');
  if (viajeId != null && pathname.endsWith('/detalle-operador')) {
    final detalle = mockDetalleViajeJson(viajeId);
    if (detalle == null) throw ApiException('Viaje $viajeId no encontrado (demo)');
    return detalle;
  }

  if (viajeId != null && pathname.endsWith('/cancelar') && method == 'PATCH') {
    final v = mockViajesOperadorJson(fechaHoyIso()).firstWhere(
      (x) => x['id'] == viajeId,
      orElse: () => mockViajesOperadorJson(fechaHoyIso()).first,
    );
    return {...v, 'estado': 'CANCELADO'};
  }

  if (viajeId != null && method == 'PUT') {
    final v = mockViajesOperadorJson(fechaHoyIso()).firstWhere(
      (x) => x['id'] == viajeId,
      orElse: () => mockViajesOperadorJson(fechaHoyIso()).first,
    );
    return {...v, ...?bodyMap};
  }

  // Consulta pública
  if (pathname == '/api/publico/viajes' && method == 'GET') {
    final fecha = q['fecha'] ?? fechaHoyIso();
    return mockViajesDisponiblesJson(
      fecha,
      origen: q['origen'],
      destino: q['destino'],
    );
  }

  final viajePublicoId = _matchId(pathname, '/api/publico/viajes/');
  if (viajePublicoId != null) {
    final detalle = mockDetalleViajeJson(viajePublicoId);
    if (detalle == null) throw ApiException('Viaje $viajePublicoId no encontrado (demo)');
    return detalle;
  }

  if (pathname.startsWith('/api/externo/tarifa-referencia-usd')) {
    final monto = double.tryParse(q['monto'] ?? '350') ?? 350;
    return {'equivalenteUsd': double.parse((monto / 36.5).toStringAsFixed(2))};
  }

  // Ventas / pasajeros
  if (pathname == '/api/ventas' && method == 'POST') {
    return mockVentaResponseJson(bodyMap ?? {});
  }

  if (pathname == '/api/pasajeros/manifiesto') {
    final fecha = q['fecha'] ?? fechaHoyIso();
    var list = mockManifiestoJson(fecha);
    if (q['viajeId'] != null) {
      final id = int.parse(q['viajeId']!);
      list = list.where((p) => p['viajeId'] == id).toList();
    }
    if (q['busId'] != null) {
      final busIdVal = int.parse(q['busId']!);
      Map<String, dynamic>? bus;
      for (final b in mockBusesJson) {
        if (b['id'] == busIdVal) {
          bus = b;
          break;
        }
      }
      if (bus != null) {
        list = list.where((p) => p['busNumeroInterno'] == bus!['numeroInterno']).toList();
      }
    }
    return list;
  }

  if (pathname == '/api/reservas-excepcionales' && method == 'POST') {
    return {'id': 5001, 'numeroAsiento': 25};
  }

  // Reportes
  if (pathname == '/api/reportes/ocupacion') {
    final fecha = q['fecha'] ?? fechaHoyIso();
    var list = mockOcupacionJson(fecha);
    if (q['empresaId'] != null) {
      final empId = int.parse(q['empresaId']!);
      final ids = mockViajesOperadorJson(fecha)
          .where((v) => v['empresaId'] == empId)
          .map((v) => v['id'])
          .toSet();
      list = list.where((o) => ids.contains(o['viajeId'])).toList();
    }
    return list;
  }

  if (pathname == '/api/reportes/ingresos') {
    final desde = q['desde'] ?? fechaHoyIso();
    final hasta = q['hasta'] ?? fechaHoyIso();
    return mockIngresosJson(desde, hasta);
  }

  // Paradas
  if (pathname == '/api/paradas' && method == 'GET') {
    final origen = q['origen'];
    final destino = q['destino'];
    if (origen != null && destino != null) {
      return mockParadasForRoute(origen, destino);
    }
    return mockParadasBfsMgaJson;
  }

  if (pathname == '/api/paradas' && method == 'POST') {
    return {
      'id': mockParadasBfsMgaJson.length + 1,
      'nombre': bodyMap?['nombre'] ?? 'Parada demo',
      'orden': mockParadasBfsMgaJson.length + 1,
      'minutosDesdeSalida': bodyMap?['minutosDesdeSalida'] ?? 0,
      'horaEstimada': '08:00:00',
      'latitud': bodyMap?['latitud'] ?? 12.0,
      'longitud': bodyMap?['longitud'] ?? -86.0,
    };
  }

  final paradaId = _matchId(pathname, '/api/paradas/');
  if (paradaId != null && method == 'PUT') {
    final p = mockParadasBfsMgaJson.cast<Map<String, dynamic>>().firstWhere(
          (x) => x['id'] == paradaId,
          orElse: () => mockParadasBfsMgaJson.first,
        );
    return {...p, ...?bodyMap};
  }

  if (paradaId != null && method == 'DELETE') return null;

  throw ApiException('[Modo demo] Ruta no simulada: $method $pathname');
}

List<Map<String, dynamic>> _buildAsientosBusJson(int busId) {
  final asientos = <Map<String, dynamic>>[];
  var numero = 1;
  for (var fila = 1; fila <= 12; fila++) {
    for (final pos in ['VENTANA', 'PASILLO']) {
      if (numero > 45) break;
      asientos.add({
        'id': busId * 100 + numero,
        'numero': numero,
        'fila': fila,
        'posicion': pos,
      });
      numero++;
    }
  }
  for (var i = 1; i <= 5; i++) {
    asientos.add({
      'id': busId * 100 + numero,
      'numero': numero,
      'fila': 13,
      'posicion': 'TRASERA_$i',
    });
    numero++;
  }
  return asientos;
}
