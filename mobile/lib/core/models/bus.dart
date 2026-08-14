class AsientoBus {
  AsientoBus({
    required this.id,
    required this.numero,
    required this.fila,
    required this.posicion,
  });

  final int id;
  final int numero;
  final int fila;
  final String posicion;

  factory AsientoBus.fromJson(Map<String, dynamic> json) => AsientoBus(
        id: json['id'] as int,
        numero: json['numero'] as int,
        fila: json['fila'] as int,
        posicion: json['posicion'] as String,
      );
}

class Bus {
  Bus({
    required this.id,
    required this.empresaId,
    required this.numeroInterno,
    required this.placa,
    required this.capacidad,
    required this.filas,
    required this.activo,
    this.fotoUrl,
    required this.sede,
    this.asientos = const [],
  });

  final int id;
  final int empresaId;
  final String numeroInterno;
  final String placa;
  final int capacidad;
  final int filas;
  final bool activo;
  final String? fotoUrl;
  final String sede;
  final List<AsientoBus> asientos;

  factory Bus.fromJson(Map<String, dynamic> json) {
    final asientosJson = json['asientos'] as List<dynamic>? ?? [];
    return Bus(
      id: json['id'] as int,
      empresaId: json['empresaId'] as int,
      numeroInterno: json['numeroInterno'] as String,
      placa: json['placa'] as String,
      capacidad: (json['capacidad'] as num).toInt(),
      filas: (json['filas'] as num?)?.toInt() ?? 0,
      activo: json['activo'] as bool? ?? true,
      fotoUrl: json['fotoUrl'] as String?,
      sede: json['sede'] as String,
      asientos: asientosJson.map((e) => AsientoBus.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
