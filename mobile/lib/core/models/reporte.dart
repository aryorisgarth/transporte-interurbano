class OcupacionViaje {
  OcupacionViaje({
    required this.viajeId,
    required this.fecha,
    required this.horaSalida,
    required this.origen,
    required this.destino,
    required this.busNumeroInterno,
    required this.busPlaca,
    required this.capacidadTotal,
    required this.asientosVendidos,
    required this.asientosReservados,
    required this.asientosDisponibles,
    required this.porcentajeOcupacion,
  });

  final int viajeId;
  final String fecha;
  final String horaSalida;
  final String origen;
  final String destino;
  final String busNumeroInterno;
  final String busPlaca;
  final int capacidadTotal;
  final int asientosVendidos;
  final int asientosReservados;
  final int asientosDisponibles;
  final double porcentajeOcupacion;

  factory OcupacionViaje.fromJson(Map<String, dynamic> json) => OcupacionViaje(
        viajeId: json['viajeId'] as int,
        fecha: json['fecha'] as String,
        horaSalida: json['horaSalida'] as String,
        origen: json['origen'] as String,
        destino: json['destino'] as String,
        busNumeroInterno: json['busNumeroInterno'] as String,
        busPlaca: json['busPlaca'] as String,
        capacidadTotal: (json['capacidadTotal'] as num).toInt(),
        asientosVendidos: (json['asientosVendidos'] as num).toInt(),
        asientosReservados: (json['asientosReservados'] as num).toInt(),
        asientosDisponibles: (json['asientosDisponibles'] as num).toInt(),
        porcentajeOcupacion: (json['porcentajeOcupacion'] as num).toDouble(),
      );
}

class IngresosReporte {
  IngresosReporte({
    required this.desde,
    required this.hasta,
    required this.resumen,
    required this.porDia,
    required this.porViaje,
    required this.porCajero,
    required this.porTerminal,
    required this.ventas,
  });

  final String desde;
  final String hasta;
  final Map<String, dynamic> resumen;
  final List<Map<String, dynamic>> porDia;
  final List<Map<String, dynamic>> porViaje;
  final List<Map<String, dynamic>> porCajero;
  final List<Map<String, dynamic>> porTerminal;
  final List<Map<String, dynamic>> ventas;

  factory IngresosReporte.fromJson(Map<String, dynamic> json) => IngresosReporte(
        desde: json['desde'] as String,
        hasta: json['hasta'] as String,
        resumen: Map<String, dynamic>.from(json['resumen'] as Map? ?? {}),
        porDia: (json['porDia'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        porViaje: (json['porViaje'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        porCajero: (json['porCajero'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        porTerminal: (json['porTerminal'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        ventas: (json['ventas'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );
}
