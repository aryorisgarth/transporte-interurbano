class Empresa {
  Empresa({
    required this.id,
    required this.nombre,
    this.telefono,
    this.correo,
    required this.tarifaEquipajeExtra,
    this.logoUrl,
    required this.activo,
  });

  final int id;
  final String nombre;
  final String? telefono;
  final String? correo;
  final double tarifaEquipajeExtra;
  final String? logoUrl;
  final bool activo;

  factory Empresa.fromJson(Map<String, dynamic> json) => Empresa(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        telefono: json['telefono'] as String?,
        correo: json['correo'] as String?,
        tarifaEquipajeExtra: (json['tarifaEquipajeExtra'] as num).toDouble(),
        logoUrl: json['logoUrl'] as String?,
        activo: json['activo'] as bool? ?? true,
      );
}

class ResumenEmpresa {
  ResumenEmpresa({
    required this.id,
    required this.nombre,
    required this.activo,
    required this.busesActivos,
    required this.operadoresActivos,
    required this.viajesHoy,
    required this.boletosVendidosHoy,
  });

  final int id;
  final String nombre;
  final bool activo;
  final int busesActivos;
  final int operadoresActivos;
  final int viajesHoy;
  final int boletosVendidosHoy;

  factory ResumenEmpresa.fromJson(Map<String, dynamic> json) => ResumenEmpresa(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        activo: json['activo'] as bool? ?? true,
        busesActivos: (json['busesActivos'] as num?)?.toInt() ?? 0,
        operadoresActivos: (json['operadoresActivos'] as num?)?.toInt() ?? 0,
        viajesHoy: (json['viajesHoy'] as num?)?.toInt() ?? 0,
        boletosVendidosHoy: (json['boletosVendidosHoy'] as num?)?.toInt() ?? 0,
      );
}

class DetalleCooperativa {
  DetalleCooperativa({
    required this.empresa,
    required this.metricas,
    required this.operadores,
    required this.buses,
  });

  final Empresa empresa;
  final Map<String, int> metricas;
  final List<Map<String, dynamic>> operadores;
  final List<Map<String, dynamic>> buses;

  factory DetalleCooperativa.fromJson(Map<String, dynamic> json) {
    final m = json['metricas'] as Map<String, dynamic>? ?? {};
    return DetalleCooperativa(
      empresa: Empresa.fromJson(json['empresa'] as Map<String, dynamic>),
      metricas: m.map((k, v) => MapEntry(k, (v as num).toInt())),
      operadores: (json['operadores'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      buses: (json['buses'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}
