class ViajeDisponible {
  ViajeDisponible({
    required this.viajeId,
    required this.empresaNombre,
    this.empresaLogoUrl,
    required this.horaSalida,
    required this.asientosDisponibles,
    required this.capacidadTotal,
    required this.tarifa,
  });

  final int viajeId;
  final String empresaNombre;
  final String? empresaLogoUrl;
  final String horaSalida;
  final int asientosDisponibles;
  final int capacidadTotal;
  final double tarifa;

  factory ViajeDisponible.fromJson(Map<String, dynamic> json) {
    return ViajeDisponible(
      viajeId: json['viajeId'] as int,
      empresaNombre: json['empresaNombre'] as String,
      empresaLogoUrl: json['empresaLogoUrl'] as String?,
      horaSalida: json['horaSalida'] as String,
      asientosDisponibles: (json['asientosDisponibles'] as num).toInt(),
      capacidadTotal: (json['capacidadTotal'] as num).toInt(),
      tarifa: (json['tarifa'] as num).toDouble(),
    );
  }
}

class AsientoViaje {
  AsientoViaje({
    required this.viajeAsientoId,
    required this.numero,
    required this.fila,
    required this.posicion,
    required this.estado,
  });

  final int viajeAsientoId;
  final int numero;
  final int fila;
  final String posicion;
  final String estado;

  factory AsientoViaje.fromJson(Map<String, dynamic> json) {
    return AsientoViaje(
      viajeAsientoId: json['viajeAsientoId'] as int,
      numero: json['numero'] as int,
      fila: json['fila'] as int,
      posicion: json['posicion'] as String,
      estado: json['estado'] as String,
    );
  }

  bool get esVentana => posicion == 'VENTANA' || posicion.startsWith('TRASERA');
}

class DetalleViaje {
  DetalleViaje({
    required this.viajeId,
    required this.empresaNombre,
    this.empresaLogoUrl,
    this.busNumeroInterno,
    this.busFotoUrl,
    required this.origen,
    required this.destino,
    required this.fecha,
    required this.horaSalida,
    required this.tarifa,
    required this.tarifaEquipajeExtra,
    required this.asientosDisponibles,
    required this.asientos,
  });

  final int viajeId;
  final String empresaNombre;
  final String? empresaLogoUrl;
  final String? busNumeroInterno;
  final String? busFotoUrl;
  final String origen;
  final String destino;
  final String fecha;
  final String horaSalida;
  final double tarifa;
  final double tarifaEquipajeExtra;
  final int asientosDisponibles;
  final List<AsientoViaje> asientos;

  factory DetalleViaje.fromJson(Map<String, dynamic> json) {
    final asientosJson = json['asientos'] as List<dynamic>? ?? [];
    return DetalleViaje(
      viajeId: json['viajeId'] as int,
      empresaNombre: json['empresaNombre'] as String,
      empresaLogoUrl: json['empresaLogoUrl'] as String?,
      busNumeroInterno: json['busNumeroInterno'] as String?,
      busFotoUrl: json['busFotoUrl'] as String?,
      origen: json['origen'] as String,
      destino: json['destino'] as String,
      fecha: json['fecha'] as String,
      horaSalida: json['horaSalida'] as String,
      tarifa: (json['tarifa'] as num).toDouble(),
      tarifaEquipajeExtra: (json['tarifaEquipajeExtra'] as num).toDouble(),
      asientosDisponibles: (json['asientosDisponibles'] as num).toInt(),
      asientos: asientosJson
          .map((e) => AsientoViaje.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
