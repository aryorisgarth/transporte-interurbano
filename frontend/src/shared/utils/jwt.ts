/** Decodifica payload JWT (sin verificar firma; solo UI de roles). */
export function decodeJwtPayload(token: string): Record<string, unknown> | null {
  try {
    const part = token.split('.')[1];
    if (!part) return null;
    const json = atob(part.replace(/-/g, '+').replace(/_/g, '/'));
    return JSON.parse(json);
  } catch {
    return null;
  }
}

export function extractRolesFromToken(token: string): string[] {
  const payload = decodeJwtPayload(token);
  if (!payload) return [];

  const roles = new Set<string>();

  const realmAccess = payload.realm_access as { roles?: string[] } | undefined;
  realmAccess?.roles?.forEach((r) => roles.add(r));

  const resourceAccess = payload.resource_access as
    | Record<string, { roles?: string[] }>
    | undefined;
  if (resourceAccess) {
    Object.values(resourceAccess).forEach((client) => {
      client.roles?.forEach((r) => roles.add(r));
    });
  }

  return [...roles];
}

export function hasAnyRole(roles: string[], required: string[]): boolean {
  return required.some((r) => roles.includes(r));
}

export const ROLES = {
  CAJERO: 'CAJERO',
  ADMIN_EMPRESA: 'ADMIN_EMPRESA',
  ADMIN_GENERAL: 'ADMIN_GENERAL',
  RESERVA_EXCEPCIONAL: 'RESERVA_EXCEPCIONAL',
} as const;

export function isCajero(roles: string[]) {
  return roles.includes(ROLES.CAJERO);
}

export function isAdmin(roles: string[]) {
  return hasAnyRole(roles, [ROLES.ADMIN_EMPRESA, ROLES.ADMIN_GENERAL]);
}

/** Solo personal de mostrador — no admins de empresa ni plataforma. */
export function puedeUsarPanelCajero(roles: string[]) {
  return (
    roles.includes(ROLES.CAJERO) &&
    !roles.includes(ROLES.ADMIN_EMPRESA) &&
    !roles.includes(ROLES.ADMIN_GENERAL)
  );
}

export function esAdminGlobal(roles: string[]) {
  return roles.includes(ROLES.ADMIN_GENERAL);
}

export function esAdminEmpresa(roles: string[]) {
  return roles.includes(ROLES.ADMIN_EMPRESA) && !roles.includes(ROLES.ADMIN_GENERAL);
}

/** Ruta post-login según roles; respeta `from` solo si el rol lo permite. */
export function rutaInicio(roles: string[], from?: string): string {
  if (from?.startsWith('/admin') && isAdmin(roles)) return from;
  if (from?.startsWith('/cajero') && puedeUsarPanelCajero(roles)) return from;
  if (isAdmin(roles)) return '/admin';
  if (puedeUsarPanelCajero(roles)) return '/cajero';
  return '/acceso';
}
