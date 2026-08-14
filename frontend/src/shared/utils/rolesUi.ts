import { ROLES } from './jwt';

export const ROLE_LABELS: Record<string, string> = {
  [ROLES.CAJERO]: 'Cajero de terminal',
  [ROLES.ADMIN_EMPRESA]: 'Administrador de empresa',
  [ROLES.ADMIN_GENERAL]: 'Administrador de plataforma',
  [ROLES.RESERVA_EXCEPCIONAL]: 'Reserva excepcional',
};

export const ROLE_COLORS: Record<string, 'default' | 'primary' | 'secondary' | 'success' | 'warning' | 'info'> = {
  [ROLES.CAJERO]: 'primary',
  [ROLES.ADMIN_EMPRESA]: 'secondary',
  [ROLES.ADMIN_GENERAL]: 'info',
  [ROLES.RESERVA_EXCEPCIONAL]: 'warning',
};

export function primaryRoleLabel(roles: string[]): string {
  if (roles.includes(ROLES.ADMIN_GENERAL)) return ROLE_LABELS[ROLES.ADMIN_GENERAL];
  if (roles.includes(ROLES.ADMIN_EMPRESA)) return ROLE_LABELS[ROLES.ADMIN_EMPRESA];
  if (roles.includes(ROLES.CAJERO)) return ROLE_LABELS[ROLES.CAJERO];
  return 'Usuario';
}
