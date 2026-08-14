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

  factory ViajeDisponible.fromJson(Map<String, dynamic> json) => ViajeDisponible(
        viajeId: json['viajeId'] as int,
        empresaNombre: json['empresaNombre'] as String,
        empresaLogoUrl: json['empresaLogoUrl'] as String?,
        horaSalida: json['horaSalida'] as String,
        asientosDisponibles: (json['asientosDisponibles'] as num).toInt(),
        capacidadTotal: (json['capacidadTotal'] as num).toInt(),
        tarifa: (json['tarifa'] as num).toDouble(),
      );
}

class ParadaRuta {
  ParadaRuta({
    required this.id,
    required this.nombre,
    required this.orden,
    this.minutosDesdeSalida,
    this.horaEstimada,
    this.latitud,
    this.longitud,
  });

  final int id;
  final String nombre;
  final int orden;
  final int? minutosDesdeSalida;
  final String? horaEstimada;
  final double? latitud;
  final double? longitud;

  factory ParadaRuta.fromJson(Map<String, dynamic> json) => ParadaRuta(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        orden: json['orden'] as int,
        minutosDesdeSalida: (json['minutosDesdeSalida'] as num?)?.toInt(),
        horaEstimada: json['horaEstimada'] as String?,
        latitud: (json['latitud'] as num?)?.toDouble(),
        longitud: (json['longitud'] as num?)?.toDouble(),
      );
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

  factory AsientoViaje.fromJson(Map<String, dynamic> json) => AsientoViaje(
        viajeAsientoId: json['viajeAsientoId'] as int,
        numero: json['numero'] as int,
        fila: json['fila'] as int,
        posicion: json['posicion'] as String,
        estado: json['estado'] as String,
      );

  bool get esVentana => posicion == 'VENTANA' || posicion.startsWith('TRASERA');
  bool get disponible => estado == 'DISPONIBLE';
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
    this.paradas = const [],
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
  final List<ParadaRuta> paradas;

  factory DetalleViaje.fromJson(Map<String, dynamic> json) {
    final asientosJson = json['asientos'] as List<dynamic>? ?? [];
    final paradasJson = json['paradas'] as List<dynamic>? ?? [];
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
      asientos: asientosJson.map((e) => AsientoViaje.fromJson(e as Map<String, dynamic>)).toList(),
      paradas: paradasJson.map((e) => ParadaRuta.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class ViajeOperador {
  ViajeOperador({
    required this.id,
    required this.empresaId,
    required this.empresaNombre,
    required this.busId,
    required this.busNumeroInterno,
    required this.origen,
    required this.destino,
    required this.fecha,
    required this.horaSalida,
    required this.tarifa,
    this.tarifaEquipajeExtra,
    required this.estado,
    required this.asientosDisponibles,
  });

  final int id;
  final int empresaId;
  final String empresaNombre;
  final int busId;
  final String busNumeroInterno;
  final String origen;
  final String destino;
  final String fecha;
  final String horaSalida;
  final double tarifa;
  final double? tarifaEquipajeExtra;
  final String estado;
  final int asientosDisponibles;

  factory ViajeOperador.fromJson(Map<String, dynamic> json) => ViajeOperador(
        id: json['id'] as int,
        empresaId: json['empresaId'] as int,
        empresaNombre: json['empresaNombre'] as String,
        busId: json['busId'] as int,
        busNumeroInterno: json['busNumeroInterno'] as String,
        origen: json['origen'] as String,
        destino: json['destino'] as String,
        fecha: json['fecha'] as String,
        horaSalida: json['horaSalida'] as String,
        tarifa: (json['tarifa'] as num).toDouble(),
        tarifaEquipajeExtra: (json['tarifaEquipajeExtra'] as num?)?.toDouble(),
        estado: json['estado'] as String,
        asientosDisponibles: (json['asientosDisponibles'] as num).toInt(),
      );
}
