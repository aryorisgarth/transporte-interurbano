import 'package:intl/intl.dart';

String formatearCordobas(double monto) {
  final fmt = NumberFormat.currency(locale: 'es_NI', symbol: 'C\$', decimalDigits: 2);
  return fmt.format(monto);
}

/// "06:00:00" → "6:00 AM" (formato Nicaragua, 12 horas).
String formatearHora(String hora) {
  final parts = hora.trim().split(':');
  if (parts.isEmpty) return hora;

  final h24 = int.tryParse(parts[0]) ?? -1;
  if (h24 < 0 || h24 > 23) return hora;

  final minRaw = parts.length > 1 ? parts[1] : '00';
  final min = minRaw.length >= 2 ? minRaw.substring(0, 2) : minRaw.padLeft(2, '0');

  final esPm = h24 >= 12;
  var h12 = h24 % 12;
  if (h12 == 0) h12 = 12;

  return '$h12:$min ${esPm ? 'PM' : 'AM'}';
}

/// Parsea "1:30 PM" → "13:30" para enviar al backend.
String horaNicaraguaA24h(String hora12) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false).firstMatch(hora12.trim());
  if (match == null) return hora12;

  var h = int.parse(match.group(1)!);
  final m = match.group(2)!;
  final ampm = match.group(3)!.toUpperCase();

  if (ampm == 'AM') {
    if (h == 12) h = 0;
  } else if (h != 12) {
    h += 12;
  }

  return '${h.toString().padLeft(2, '0')}:$m';
}

/// Acepta "6:00 AM" o "06:00" y devuelve "HH:mm" para la API.
String horaParaBackend(String hora) {
  final t = hora.trim();
  if (RegExp(r'^\d{1,2}:\d{2}\s*(AM|PM)$', caseSensitive: false).hasMatch(t)) {
    return horaNicaraguaA24h(t);
  }
  final match = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$').firstMatch(t);
  if (match != null) {
    final h = int.parse(match.group(1)!);
    final min = match.group(2)!;
    return '${h.toString().padLeft(2, '0')}:$min';
  }
  return t;
}

class HoraSalidaNicaragua {
  const HoraSalidaNicaragua({required this.hora, required this.minuto, required this.ampm});

  final int hora;
  final String minuto;
  final String ampm;

  static const inicial = HoraSalidaNicaragua(hora: 6, minuto: '00', ampm: 'AM');

  factory HoraSalidaNicaragua.desdeBackend(String hora24) => descomponerHora24(hora24);

  String toNicaragua() => '$hora:$minuto $ampm';

  String toBackend() => horaParaBackend(toNicaragua());
}

HoraSalidaNicaragua descomponerHora24(String hora24) {
  final parts = hora24.trim().split(':');
  if (parts.isEmpty) return HoraSalidaNicaragua.inicial;

  final h24 = int.tryParse(parts[0]) ?? -1;
  if (h24 < 0 || h24 > 23) return HoraSalidaNicaragua.inicial;

  final minRaw = parts.length > 1 ? parts[1] : '00';
  final min = minRaw.length >= 2 ? minRaw.substring(0, 2) : minRaw.padLeft(2, '0');

  final esPm = h24 >= 12;
  var h12 = h24 % 12;
  if (h12 == 0) h12 = 12;

  return HoraSalidaNicaragua(hora: h12, minuto: min, ampm: esPm ? 'PM' : 'AM');
}

String fechaHoyIso() {
  return DateFormat('yyyy-MM-dd').format(DateTime.now());
}

String formatearFechaCorta(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  return '${d.day} ${meses[d.month - 1]}';
}

String etiquetaEstadoAsiento(String estado) {
  switch (estado) {
    case 'DISPONIBLE':
      return 'Disponible';
    case 'VENDIDO':
      return 'Vendido';
    case 'CANCELADO':
      return 'Cancelado';
    case 'RESERVADO_EXCEPCIONAL':
      return 'Reservado';
    default:
      return estado;
  }
}
