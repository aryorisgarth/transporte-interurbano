/// Terminal del cajero: sede en BD o inferida del username.
String? resolverTerminalCajero({String? sede, String? username}) {
  final s = sede?.trim();
  if (s != null && s.isNotEmpty) return s;

  final u = (username ?? '').toLowerCase();
  if (u.contains('.mga') || u.endsWith('mga')) return 'Managua';
  if (u.contains('.bfs') || u.contains('bluefields')) return 'Bluefields';
  if (u.contains('managua')) return 'Managua';
  if (u.contains('wendelyn') && !u.contains('mga')) return 'Bluefields';
  return null;
}

String etiquetaTerminal(String? terminal) => terminal ?? 'Sin asignar';
