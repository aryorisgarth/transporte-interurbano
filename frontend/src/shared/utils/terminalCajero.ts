/** Terminal del cajero: sede en BD o inferida del username (ej. cajero.wendelyn.mga → Managua). */
export function resolverTerminalCajero(
  perfil: { sede?: string | null } | null | undefined,
  username?: string | null
): string | null {
  const sede = perfil?.sede?.trim();
  if (sede) return sede;

  const u = (username ?? '').toLowerCase();
  if (u.includes('.mga') || u.endsWith('mga')) return 'Managua';
  if (u.includes('.bfs') || u.includes('bluefields')) return 'Bluefields';
  if (u.includes('managua')) return 'Managua';
  if (u.includes('martinez') && u.includes('mga')) return 'Managua';
  if (u.includes('wendelyn') && !u.includes('mga')) return 'Bluefields';
  return null;
}

export function etiquetaTerminal(terminal: string | null): string {
  return terminal ?? 'Sin asignar';
}
