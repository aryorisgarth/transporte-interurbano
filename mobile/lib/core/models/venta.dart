class VentaResponse {
  VentaResponse({
    required this.id,
    required this.codigo,
    required this.viajeId,
    required this.compradorNombre,
    required this.compradorCedula,
    this.compradorTelefono,
    required this.numerosAsiento,
    required this.subtotalBoletos,
    required this.subtotalEquipaje,
    required this.total,
  });

  final int id;
  final String codigo;
  final int viajeId;
  final String compradorNombre;
  final String compradorCedula;
  final String? compradorTelefono;
  final List<int> numerosAsiento;
  final double subtotalBoletos;
  final double subtotalEquipaje;
  final double total;

  factory VentaResponse.fromJson(Map<String, dynamic> json) => VentaResponse(
        id: json['id'] as int,
        codigo: json['codigo'] as String,
        viajeId: json['viajeId'] as int,
        compradorNombre: json['compradorNombre'] as String,
        compradorCedula: json['compradorCedula'] as String,
        compradorTelefono: json['compradorTelefono'] as String?,
        numerosAsiento: (json['numerosAsiento'] as List<dynamic>).map((e) => (e as num).toInt()).toList(),
        subtotalBoletos: (json['subtotalBoletos'] as num).toDouble(),
        subtotalEquipaje: (json['subtotalEquipaje'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
      );
}

class ManifiestoPasajero {
  ManifiestoPasajero({
    required this.boletoId,
    required this.viajeId,
    required this.fechaViaje,
    required this.horaSalida,
    required this.origen,
    required this.destino,
    required this.busNumeroInterno,
    required this.busPlaca,
    required this.numeroAsiento,
    required this.pasajeroNombre,
    required this.pasajeroCedula,
    this.pasajeroTelefono,
    required this.codigoVenta,
    required this.operadorNombre,
    required this.estadoBoleto,
    required this.esMenor,
  });

  final int boletoId;
  final int viajeId;
  final String fechaViaje;
  final String horaSalida;
  final String origen;
  final String destino;
  final String busNumeroInterno;
  final String busPlaca;
  final int numeroAsiento;
  final String pasajeroNombre;
  final String pasajeroCedula;
  final String? pasajeroTelefono;
  final String codigoVenta;
  final String operadorNombre;
  final String estadoBoleto;
  final bool esMenor;

  factory ManifiestoPasajero.fromJson(Map<String, dynamic> json) => ManifiestoPasajero(
        boletoId: json['boletoId'] as int,
        viajeId: json['viajeId'] as int,
        fechaViaje: json['fechaViaje'] as String,
        horaSalida: json['horaSalida'] as String,
        origen: json['origen'] as String,
        destino: json['destino'] as String,
        busNumeroInterno: json['busNumeroInterno'] as String,
        busPlaca: json['busPlaca'] as String,
        numeroAsiento: (json['numeroAsiento'] as num).toInt(),
        pasajeroNombre: json['pasajeroNombre'] as String,
        pasajeroCedula: json['pasajeroCedula'] as String,
        pasajeroTelefono: json['pasajeroTelefono'] as String?,
        codigoVenta: json['codigoVenta'] as String,
        operadorNombre: json['operadorNombre'] as String,
        estadoBoleto: json['estadoBoleto'] as String,
        esMenor: json['esMenor'] as bool? ?? false,
      );
}
