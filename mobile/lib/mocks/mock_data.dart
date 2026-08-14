import '../core/utils/formato.dart';
import 'mock_demo_profile.dart';

const mockDelayMs = 120;

/// Asientos vendidos por viaje (demo estático).
const mockVendidosPorViaje = <int, List<int>>{
  101: [1, 2, 3, 5, 8, 12, 15, 20, 22, 30],
  103: [4, 6, 7, 9],
  104: [11, 13, 14],
  102: [2, 4, 6, 8, 10, 12, 14, 16],
  105: [1, 3, 5],
  201: [10, 11, 15, 18],
  202: [5, 7],
  203: [3, 6, 9, 12],
  301: [1, 2, 4, 8, 16, 24],
  302: [6, 7, 8],
};

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

List<Map<String, dynamic>> buildAsientosViajeJson(int viajeId, List<int> vendidos) {
  return _buildAsientosBusJson(viajeId).map((a) {
    final numero = a['numero'] as int;
    return {
      'viajeAsientoId': viajeId * 1000 + numero,
      'numero': numero,
      'fila': a['fila'],
      'posicion': a['posicion'],
      'estado': vendidos.contains(numero) ? 'VENDIDO' : 'DISPONIBLE',
    };
  }).toList();
}

final mockEmpresasJson = [
  {
    'id': 1,
    'nombre': 'Wendelyn Transporte',
    'telefono': '2572-3456',
    'correo': 'info@wendelyn.com',
    'tarifaEquipajeExtra': 150.0,
    'logoUrl': null,
    'activo': true,
  },
  {
    'id': 2,
    'nombre': 'Martínez Líneas',
    'telefono': '2572-7890',
    'correo': 'info@martinez.com',
    'tarifaEquipajeExtra': 120.0,
    'logoUrl': null,
    'activo': true,
  },
  {
    'id': 3,
    'nombre': 'Costa Caribe Express',
    'telefono': '2572-1122',
    'correo': 'info@costacaribe.com',
    'tarifaEquipajeExtra': 140.0,
    'logoUrl': null,
    'activo': true,
  },
];

final mockBusesJson = [
  {
    'id': 1,
    'empresaId': 1,
    'numeroInterno': 'W-01',
    'placa': 'NI-1001',
    'capacidad': 50,
    'filas': 13,
    'activo': true,
    'fotoUrl': '/images/bus-yutong-interurbano.png',
    'sede': 'Bluefields',
    'asientos': _buildAsientosBusJson(1),
  },
  {
    'id': 2,
    'empresaId': 1,
    'numeroInterno': 'W-02',
    'placa': 'NI-1002',
    'capacidad': 50,
    'filas': 13,
    'activo': true,
    'fotoUrl': '/images/bus-yutong-interurbano.png',
    'sede': 'Managua',
    'asientos': _buildAsientosBusJson(2),
  },
  {
    'id': 3,
    'empresaId': 1,
    'numeroInterno': 'W-03',
    'placa': 'NI-1003',
    'capacidad': 50,
    'filas': 13,
    'activo': true,
    'fotoUrl': '/images/bus-yutong-interurbano.png',
    'sede': 'Bluefields',
    'asientos': _buildAsientosBusJson(3),
  },
  {
    'id': 4,
    'empresaId': 2,
    'numeroInterno': 'M-01',
    'placa': 'NI-2001',
    'capacidad': 50,
    'filas': 13,
    'activo': true,
    'fotoUrl': '/images/bus-yutong-interurbano.png',
    'sede': 'Bluefields',
    'asientos': _buildAsientosBusJson(4),
  },
  {
    'id': 5,
    'empresaId': 2,
    'numeroInterno': 'M-02',
    'placa': 'NI-2002',
    'capacidad': 50,
    'filas': 13,
    'activo': true,
    'fotoUrl': '/images/bus-yutong-interurbano.png',
    'sede': 'Managua',
    'asientos': _buildAsientosBusJson(5),
  },
  {
    'id': 6,
    'empresaId': 3,
    'numeroInterno': 'CC-01',
    'placa': 'NI-3101',
    'capacidad': 50,
    'filas': 13,
    'activo': true,
    'fotoUrl': '/images/bus-yutong-interurbano.png',
    'sede': 'Bluefields',
    'asientos': _buildAsientosBusJson(6),
  },
  {
    'id': 7,
    'empresaId': 3,
    'numeroInterno': 'CC-02',
    'placa': 'NI-3102',
    'capacidad': 50,
    'filas': 13,
    'activo': true,
    'fotoUrl': '/images/bus-yutong-interurbano.png',
    'sede': 'Managua',
    'asientos': _buildAsientosBusJson(7),
  },
];

Map<String, dynamic> _viajeTemplate({
  required int id,
  required int empresaId,
  required String empresaNombre,
  required int busId,
  required String busNumeroInterno,
  required String origen,
  required String destino,
  required String horaSalida,
  required double tarifa,
  required double tarifaEquipajeExtra,
  required int asientosDisponibles,
}) =>
    {
      'id': id,
      'empresaId': empresaId,
      'empresaNombre': empresaNombre,
      'busId': busId,
      'busNumeroInterno': busNumeroInterno,
      'origen': origen,
      'destino': destino,
      'horaSalida': horaSalida,
      'tarifa': tarifa,
      'tarifaEquipajeExtra': tarifaEquipajeExtra,
      'estado': 'PROGRAMADO',
      'asientosDisponibles': asientosDisponibles,
    };

List<Map<String, dynamic>> mockViajesOperadorJson(String fecha) {
  const cap = 50;
  int disp(int id) => cap - (mockVendidosPorViaje[id]?.length ?? 0);

  final templates = [
    // Wendelyn — Bluefields → Managua
    _viajeTemplate(
      id: 101,
      empresaId: 1,
      empresaNombre: 'Wendelyn Transporte',
      busId: 1,
      busNumeroInterno: 'W-01',
      origen: 'Bluefields',
      destino: 'Managua',
      horaSalida: '06:00:00',
      tarifa: 350,
      tarifaEquipajeExtra: 150,
      asientosDisponibles: disp(101),
    ),
    _viajeTemplate(
      id: 103,
      empresaId: 1,
      empresaNombre: 'Wendelyn Transporte',
      busId: 3,
      busNumeroInterno: 'W-03',
      origen: 'Bluefields',
      destino: 'Managua',
      horaSalida: '09:00:00',
      tarifa: 350,
      tarifaEquipajeExtra: 150,
      asientosDisponibles: disp(103),
    ),
    _viajeTemplate(
      id: 104,
      empresaId: 1,
      empresaNombre: 'Wendelyn Transporte',
      busId: 1,
      busNumeroInterno: 'W-01',
      origen: 'Bluefields',
      destino: 'Managua',
      horaSalida: '12:00:00',
      tarifa: 350,
      tarifaEquipajeExtra: 150,
      asientosDisponibles: disp(104),
    ),
    // Wendelyn — Managua → Bluefields
    _viajeTemplate(
      id: 102,
      empresaId: 1,
      empresaNombre: 'Wendelyn Transporte',
      busId: 2,
      busNumeroInterno: 'W-02',
      origen: 'Managua',
      destino: 'Bluefields',
      horaSalida: '14:30:00',
      tarifa: 350,
      tarifaEquipajeExtra: 150,
      asientosDisponibles: disp(102),
    ),
    _viajeTemplate(
      id: 105,
      empresaId: 1,
      empresaNombre: 'Wendelyn Transporte',
      busId: 2,
      busNumeroInterno: 'W-02',
      origen: 'Managua',
      destino: 'Bluefields',
      horaSalida: '18:00:00',
      tarifa: 350,
      tarifaEquipajeExtra: 150,
      asientosDisponibles: disp(105),
    ),
    // Martínez
    _viajeTemplate(
      id: 201,
      empresaId: 2,
      empresaNombre: 'Martínez Líneas',
      busId: 4,
      busNumeroInterno: 'M-01',
      origen: 'Bluefields',
      destino: 'Managua',
      horaSalida: '07:30:00',
      tarifa: 320,
      tarifaEquipajeExtra: 120,
      asientosDisponibles: disp(201),
    ),
    _viajeTemplate(
      id: 202,
      empresaId: 2,
      empresaNombre: 'Martínez Líneas',
      busId: 4,
      busNumeroInterno: 'M-01',
      origen: 'Bluefields',
      destino: 'Managua',
      horaSalida: '11:00:00',
      tarifa: 320,
      tarifaEquipajeExtra: 120,
      asientosDisponibles: disp(202),
    ),
    _viajeTemplate(
      id: 203,
      empresaId: 2,
      empresaNombre: 'Martínez Líneas',
      busId: 5,
      busNumeroInterno: 'M-02',
      origen: 'Managua',
      destino: 'Bluefields',
      horaSalida: '15:00:00',
      tarifa: 320,
      tarifaEquipajeExtra: 120,
      asientosDisponibles: disp(203),
    ),
    // Costa Caribe
    _viajeTemplate(
      id: 301,
      empresaId: 3,
      empresaNombre: 'Costa Caribe Express',
      busId: 6,
      busNumeroInterno: 'CC-01',
      origen: 'Bluefields',
      destino: 'Managua',
      horaSalida: '05:45:00',
      tarifa: 345,
      tarifaEquipajeExtra: 140,
      asientosDisponibles: disp(301),
    ),
    _viajeTemplate(
      id: 302,
      empresaId: 3,
      empresaNombre: 'Costa Caribe Express',
      busId: 7,
      busNumeroInterno: 'CC-02',
      origen: 'Managua',
      destino: 'Bluefields',
      horaSalida: '16:30:00',
      tarifa: 345,
      tarifaEquipajeExtra: 140,
      asientosDisponibles: disp(302),
    ),
  ];

  return templates.map((v) => {...v, 'fecha': fecha}).toList();
}

List<Map<String, dynamic>> mockViajesDisponiblesJson(
  String fecha, {
  String? origen,
  String? destino,
}) {
  var list = mockViajesOperadorJson(fecha);
  if (origen != null && origen.isNotEmpty) {
    list = list.where((v) => v['origen'] == origen).toList();
  }
  if (destino != null && destino.isNotEmpty) {
    list = list.where((v) => v['destino'] == destino).toList();
  }
  return list
      .map(
        (v) => {
          'viajeId': v['id'],
          'empresaNombre': v['empresaNombre'],
          'empresaLogoUrl': null,
          'horaSalida': v['horaSalida'],
          'asientosDisponibles': v['asientosDisponibles'],
          'capacidadTotal': 50,
          'tarifa': v['tarifa'],
        },
      )
      .toList();
}

List<int> vendidosForViaje(int viajeId) => mockVendidosPorViaje[viajeId] ?? const [];

final mockParadasBfsMgaJson = [
  {
    'id': 1,
    'nombre': 'Terminal Bluefields',
    'orden': 1,
    'minutosDesdeSalida': 0,
    'horaEstimada': '06:00:00',
    'latitud': 12.0131,
    'longitud': -83.7634,
  },
  {
    'id': 2,
    'nombre': 'El Rama',
    'orden': 2,
    'minutosDesdeSalida': 90,
    'horaEstimada': '07:30:00',
    'latitud': 12.1597,
    'longitud': -84.2192,
  },
  {
    'id': 3,
    'nombre': 'Juigalpa',
    'orden': 3,
    'minutosDesdeSalida': 300,
    'horaEstimada': '11:00:00',
    'latitud': 12.106,
    'longitud': -85.364,
  },
  {
    'id': 4,
    'nombre': 'Terminal Managua',
    'orden': 4,
    'minutosDesdeSalida': 480,
    'horaEstimada': '14:00:00',
    'latitud': 12.1364,
    'longitud': -86.2514,
  },
];

final mockParadasMgaBfsJson = [
  {
    'id': 11,
    'nombre': 'Terminal Managua',
    'orden': 1,
    'minutosDesdeSalida': 0,
    'horaEstimada': '14:30:00',
    'latitud': 12.1364,
    'longitud': -86.2514,
  },
  {
    'id': 12,
    'nombre': 'Juigalpa',
    'orden': 2,
    'minutosDesdeSalida': 180,
    'horaEstimada': '17:30:00',
    'latitud': 12.106,
    'longitud': -85.364,
  },
  {
    'id': 13,
    'nombre': 'El Rama',
    'orden': 3,
    'minutosDesdeSalida': 390,
    'horaEstimada': '21:00:00',
    'latitud': 12.1597,
    'longitud': -84.2192,
  },
  {
    'id': 14,
    'nombre': 'Terminal Bluefields',
    'orden': 4,
    'minutosDesdeSalida': 480,
    'horaEstimada': '22:30:00',
    'latitud': 12.0131,
    'longitud': -83.7634,
  },
];

List<Map<String, dynamic>> mockParadasForRoute(String origen, String destino) {
  if (origen == 'Managua' && destino == 'Bluefields') return mockParadasMgaBfsJson;
  return mockParadasBfsMgaJson;
}

Map<String, dynamic>? mockDetalleViajeJson(int viajeId) {
  final fecha = fechaHoyIso();
  Map<String, dynamic>? viaje;
  for (final v in mockViajesOperadorJson(fecha)) {
    if (v['id'] == viajeId) {
      viaje = v;
      break;
    }
  }
  if (viaje == null) return null;
  final v = viaje;

  final vendidos = vendidosForViaje(viajeId);
  final bus = mockBusesJson.cast<Map<String, dynamic>>().firstWhere(
        (b) => b['id'] == v['busId'],
        orElse: () => mockBusesJson.first,
      );
  final origen = v['origen'] as String;
  final destino = v['destino'] as String;

  return {
    'viajeId': v['id'],
    'empresaNombre': v['empresaNombre'],
    'empresaLogoUrl': null,
    'busNumeroInterno': v['busNumeroInterno'],
    'busFotoUrl': bus['fotoUrl'],
    'origen': origen,
    'destino': destino,
    'fecha': v['fecha'],
    'horaSalida': v['horaSalida'],
    'tarifa': v['tarifa'],
    'tarifaEquipajeExtra': v['tarifaEquipajeExtra'] ?? 150.0,
    'asientosDisponibles': v['asientosDisponibles'],
    'asientos': buildAsientosViajeJson(viajeId, vendidos),
    'paradas': mockParadasForRoute(origen, destino),
  };
}

Map<String, dynamic> mockPerfilForProfile(MockDemoProfile profile) => {
      'id': switch (profile) {
        MockDemoProfile.globalAdmin => 1,
        MockDemoProfile.adminEmpresa => 3,
        MockDemoProfile.cajero => 2,
      },
      'empresaId': profile == MockDemoProfile.globalAdmin ? null : 1,
      'empresaNombre': profile == MockDemoProfile.globalAdmin ? null : 'Wendelyn Transporte',
      'nombreUsuario': profile.username,
      'emailLogin': profile.email,
      'nombreCompleto': profile.displayName,
      'sede': profile == MockDemoProfile.cajero || profile == MockDemoProfile.adminEmpresa
          ? 'Bluefields'
          : null,
      'activo': true,
      'roles': profile.roles,
    };

final mockOperadoresJson = [
  {
    'id': 2,
    'empresaId': 1,
    'empresaNombre': 'Wendelyn Transporte',
    'nombreUsuario': 'cajero.wendelyn',
    'emailLogin': 'cajero@wendelyn.com',
    'nombreCompleto': 'Cajero Wendelyn',
    'sede': 'Bluefields',
    'activo': true,
    'roles': ['CAJERO'],
  },
  {
    'id': 3,
    'empresaId': 1,
    'empresaNombre': 'Wendelyn Transporte',
    'nombreUsuario': 'admin.wendelyn',
    'emailLogin': 'admin@wendelyn.com',
    'nombreCompleto': 'Admin Wendelyn',
    'sede': 'Bluefields',
    'activo': true,
    'roles': ['ADMIN_EMPRESA'],
  },
];

final mockResumenPlataformaJson = [
  {
    'id': 1,
    'nombre': 'Wendelyn Transporte',
    'activo': true,
    'busesActivos': 3,
    'operadoresActivos': 3,
    'viajesHoy': 5,
    'boletosVendidosHoy': 28,
  },
  {
    'id': 2,
    'nombre': 'Martínez Líneas',
    'activo': true,
    'busesActivos': 2,
    'operadoresActivos': 2,
    'viajesHoy': 3,
    'boletosVendidosHoy': 14,
  },
  {
    'id': 3,
    'nombre': 'Costa Caribe Express',
    'activo': true,
    'busesActivos': 2,
    'operadoresActivos': 2,
    'viajesHoy': 2,
    'boletosVendidosHoy': 11,
  },
];

Map<String, dynamic> mockDetalleCooperativaJson(int empresaId) {
  final empresa = mockEmpresasJson.firstWhere(
    (e) => e['id'] == empresaId,
    orElse: () => mockEmpresasJson.first,
  );
  final buses = mockBusesJson.where((b) => b['empresaId'] == empresaId).toList();
  final fecha = fechaHoyIso();

  return {
    'empresa': empresa,
    'metricas': {
      'busesActivos': buses.where((b) => b['activo'] == true).length,
      'busesInactivos': buses.where((b) => b['activo'] != true).length,
      'adminsActivos': 1,
      'adminsInactivos': 0,
      'cajerosActivos': 1,
      'cajerosInactivos': 0,
      'viajesHoy': mockViajesOperadorJson(fecha).where((v) => v['empresaId'] == empresaId).length,
      'boletosVendidosHoy': mockManifiestoJson(fecha)
          .where((m) {
            final viajeId = m['viajeId'] as int;
            return mockViajesOperadorJson(fecha).any((v) => v['id'] == viajeId && v['empresaId'] == empresaId);
          })
          .length,
    },
    'operadores': mockOperadoresJson
        .where((o) => o['empresaId'] == empresaId)
        .map(
          (o) => {
            'id': o['id'],
            'nombreUsuario': o['nombreUsuario'],
            'emailLogin': o['emailLogin'],
            'nombreCompleto': o['nombreCompleto'],
            'sede': o['sede'],
            'activo': o['activo'],
            'roles': o['roles'],
          },
        )
        .toList(),
    'buses': buses
        .map(
          (b) => {
            'id': b['id'],
            'numeroInterno': b['numeroInterno'],
            'placa': b['placa'],
            'sede': b['sede'],
            'capacidad': b['capacidad'],
            'activo': b['activo'],
          },
        )
        .toList(),
  };
}

List<Map<String, dynamic>> mockManifiestoJson(String fecha) => [
      {
        'boletoId': 1,
        'viajeId': 101,
        'fechaViaje': fecha,
        'horaSalida': '06:00:00',
        'origen': 'Bluefields',
        'destino': 'Managua',
        'busNumeroInterno': 'W-01',
        'busPlaca': 'NI-1001',
        'numeroAsiento': 1,
        'pasajeroNombre': 'María López',
        'pasajeroCedula': '001-120890-0001A',
        'pasajeroTelefono': '8888-1111',
        'codigoVenta': 'VT-DEMO-001',
        'operadorNombre': 'Cajero Wendelyn',
        'estadoBoleto': 'VENDIDO',
        'esMenor': false,
      },
      {
        'boletoId': 2,
        'viajeId': 101,
        'fechaViaje': fecha,
        'horaSalida': '06:00:00',
        'origen': 'Bluefields',
        'destino': 'Managua',
        'busNumeroInterno': 'W-01',
        'busPlaca': 'NI-1001',
        'numeroAsiento': 2,
        'pasajeroNombre': 'Carlos Meza (menor)',
        'pasajeroCedula': '001-150512-0002B',
        'pasajeroTelefono': null,
        'codigoVenta': 'VT-DEMO-001',
        'operadorNombre': 'Cajero Wendelyn',
        'estadoBoleto': 'VENDIDO',
        'esMenor': true,
      },
      {
        'boletoId': 3,
        'viajeId': 101,
        'fechaViaje': fecha,
        'horaSalida': '06:00:00',
        'origen': 'Bluefields',
        'destino': 'Managua',
        'busNumeroInterno': 'W-01',
        'busPlaca': 'NI-1001',
        'numeroAsiento': 5,
        'pasajeroNombre': 'Ana Jarquín',
        'pasajeroCedula': '001-080785-0003C',
        'pasajeroTelefono': '7777-2222',
        'codigoVenta': 'VT-DEMO-002',
        'operadorNombre': 'Cajero Wendelyn',
        'estadoBoleto': 'VENDIDO',
        'esMenor': false,
      },
      {
        'boletoId': 4,
        'viajeId': 103,
        'fechaViaje': fecha,
        'horaSalida': '09:00:00',
        'origen': 'Bluefields',
        'destino': 'Managua',
        'busNumeroInterno': 'W-03',
        'busPlaca': 'NI-1003',
        'numeroAsiento': 4,
        'pasajeroNombre': 'Roberto Silva',
        'pasajeroCedula': '001-220190-0004D',
        'pasajeroTelefono': '8888-3333',
        'codigoVenta': 'VT-DEMO-003',
        'operadorNombre': 'Cajero Wendelyn',
        'estadoBoleto': 'VENDIDO',
        'esMenor': false,
      },
      {
        'boletoId': 5,
        'viajeId': 201,
        'fechaViaje': fecha,
        'horaSalida': '07:30:00',
        'origen': 'Bluefields',
        'destino': 'Managua',
        'busNumeroInterno': 'M-01',
        'busPlaca': 'NI-2001',
        'numeroAsiento': 10,
        'pasajeroNombre': 'Lucía Mendoza',
        'pasajeroCedula': '001-091288-0005E',
        'pasajeroTelefono': '7777-4444',
        'codigoVenta': 'VT-DEMO-004',
        'operadorNombre': 'Cajero Wendelyn',
        'estadoBoleto': 'VENDIDO',
        'esMenor': false,
      },
      {
        'boletoId': 6,
        'viajeId': 301,
        'fechaViaje': fecha,
        'horaSalida': '05:45:00',
        'origen': 'Bluefields',
        'destino': 'Managua',
        'busNumeroInterno': 'CC-01',
        'busPlaca': 'NI-3101',
        'numeroAsiento': 8,
        'pasajeroNombre': 'Pedro Hodgson',
        'pasajeroCedula': '001-070586-0006F',
        'pasajeroTelefono': null,
        'codigoVenta': 'VT-DEMO-005',
        'operadorNombre': 'Cajero Wendelyn',
        'estadoBoleto': 'VENDIDO',
        'esMenor': false,
      },
      {
        'boletoId': 7,
        'viajeId': 102,
        'fechaViaje': fecha,
        'horaSalida': '14:30:00',
        'origen': 'Managua',
        'destino': 'Bluefields',
        'busNumeroInterno': 'W-02',
        'busPlaca': 'NI-1002',
        'numeroAsiento': 6,
        'pasajeroNombre': 'Sofía Ríos',
        'pasajeroCedula': '001-130391-0007G',
        'pasajeroTelefono': '8888-5555',
        'codigoVenta': 'VT-DEMO-006',
        'operadorNombre': 'Cajero Wendelyn',
        'estadoBoleto': 'VENDIDO',
        'esMenor': false,
      },
    ];

List<Map<String, dynamic>> mockOcupacionJson(String fecha) {
  return mockViajesOperadorJson(fecha).map((v) {
    final vendidos = 50 - (v['asientosDisponibles'] as int);
    final bus = mockBusesJson.cast<Map<String, dynamic>>().firstWhere(
          (b) => b['id'] == v['busId'],
          orElse: () => mockBusesJson.first,
        );
    return {
      'viajeId': v['id'],
      'fecha': v['fecha'],
      'horaSalida': v['horaSalida'],
      'origen': v['origen'],
      'destino': v['destino'],
      'busNumeroInterno': v['busNumeroInterno'],
      'busPlaca': bus['placa'],
      'capacidadTotal': 50,
      'asientosVendidos': vendidos,
      'asientosReservados': 0,
      'asientosDisponibles': v['asientosDisponibles'],
      'porcentajeOcupacion': (vendidos / 50 * 100).round(),
    };
  }).toList();
}

Map<String, dynamic> mockIngresosJson(String desde, String hasta) {
  final fecha = fechaHoyIso();
  return {
    'desde': desde,
    'hasta': hasta,
    'resumen': {
      'totalIngresos': 12600,
      'subtotalBoletos': 11900,
      'subtotalEquipaje': 700,
      'cantidadVentas': 8,
      'cantidadBoletos': 34,
      'ticketPromedio': 1575,
    },
    'porDia': [
      {
        'fecha': desde,
        'totalIngresos': 6300,
        'subtotalBoletos': 5950,
        'subtotalEquipaje': 350,
        'cantidadVentas': 4,
        'cantidadBoletos': 17,
      },
    ],
    'porViaje': mockViajesOperadorJson(fecha)
        .map(
          (v) => {
            'viajeId': v['id'],
            'fecha': v['fecha'],
            'horaSalida': v['horaSalida'],
            'origen': v['origen'],
            'destino': v['destino'],
            'busNumeroInterno': v['busNumeroInterno'],
            'totalIngresos': v['id'] == 101 ? 4200 : 2100,
            'subtotalBoletos': v['id'] == 101 ? 4000 : 2000,
            'subtotalEquipaje': v['id'] == 101 ? 200 : 100,
            'cantidadVentas': v['id'] == 101 ? 3 : 2,
            'cantidadBoletos': v['id'] == 101 ? 12 : 6,
          },
        )
        .toList(),
    'porCajero': [
      {
        'operadorId': 2,
        'operadorNombre': 'Cajero Wendelyn',
        'sede': 'Bluefields',
        'totalIngresos': 8400,
        'subtotalBoletos': 8000,
        'subtotalEquipaje': 400,
        'cantidadVentas': 5,
        'cantidadBoletos': 22,
      },
    ],
    'porTerminal': [
      {'terminal': 'Bluefields', 'totalIngresos': 8400, 'cantidadVentas': 5, 'cantidadBoletos': 22},
      {'terminal': 'Managua', 'totalIngresos': 4200, 'cantidadVentas': 3, 'cantidadBoletos': 12},
    ],
    'ventas': [
      {
        'ventaId': 1,
        'codigo': 'VT-DEMO-001',
        'fechaVenta': '${desde}T08:15:00',
        'total': 850,
        'subtotalBoletos': 700,
        'subtotalEquipaje': 150,
        'cantidadBoletos': 2,
        'operadorNombre': 'Cajero Wendelyn',
        'operadorSede': 'Bluefields',
        'origen': 'Bluefields',
        'destino': 'Managua',
        'fechaViaje': desde,
        'horaSalida': '06:00:00',
      },
    ],
  };
}

Map<String, dynamic> mockVentaResponseJson(Map<String, dynamic> body) {
  final viajeId = body['viajeId'] as int? ?? 101;
  final asientoIds = (body['viajeAsientoIds'] as List<dynamic>? ?? []).map((e) => (e as num).toInt()).toList();
  final fecha = fechaHoyIso();
  final viaje = mockViajesOperadorJson(fecha).firstWhere(
    (v) => v['id'] == viajeId,
    orElse: () => mockViajesOperadorJson(fecha).first,
  );
  final tarifa = (viaje['tarifa'] as num).toDouble();
  final n = asientoIds.isEmpty ? 1 : asientoIds.length;

  return {
    'id': 9001,
    'codigo': 'VT-MOCK-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
    'viajeId': viajeId,
    'compradorNombre': body['compradorNombre'] ?? 'Pasajero Demo',
    'compradorCedula': body['compradorCedula'] ?? '001-000000-0000X',
    'compradorTelefono': body['compradorTelefono'],
    'numerosAsiento': List.generate(n, (i) => i + 1),
    'subtotalBoletos': tarifa * n,
    'subtotalEquipaje': 0.0,
    'total': tarifa * n,
  };
}
