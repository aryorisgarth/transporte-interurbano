import { ROLES } from '@/shared/utils/jwt';

/** Activa datos estáticos y auth simulada (despliegue Vercel sin backend/Keycloak). */
export const USE_MOCK = import.meta.env.VITE_USE_MOCK === 'true';

export const DEMO_USER = {
  name: 'Usuario Demo',
  username: 'demo',
  email: 'demo@transporte.com',
  roles: [ROLES.ADMIN_GENERAL, ROLES.ADMIN_EMPRESA, ROLES.CAJERO] as string[],
};
