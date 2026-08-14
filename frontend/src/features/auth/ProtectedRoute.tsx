import { Link as RouterLink, Navigate, useLocation } from 'react-router-dom';
import { Alert, Box, Button } from '@mui/material';
import { useAuth } from '@/features/auth/AuthContext';
import { ROLES, extractRolesFromToken, isAdmin, puedeUsarPanelCajero } from '@/shared/utils/jwt';

interface Props {
  children: React.ReactNode;
  roles?: string[];
}

export function ProtectedRoute({ children, roles: requiredRoles }: Props) {
  const { isAuthenticated, hasRole, token } = useAuth();
  const location = useLocation();

  if (!isAuthenticated) {
    return <Navigate to="/acceso/login" state={{ from: location.pathname }} replace />;
  }

  const userRoles = token ? extractRolesFromToken(token) : [];

  if (requiredRoles?.includes(ROLES.CAJERO) && requiredRoles.length <= 2) {
    const esRutaCajero = requiredRoles.includes(ROLES.CAJERO) && !requiredRoles.includes(ROLES.ADMIN_EMPRESA);
    if (esRutaCajero && !puedeUsarPanelCajero(userRoles)) {
      return (
        <Box py={4}>
          <Alert severity="info" sx={{ mb: 2 }}>
            El panel de venta en terminal es solo para <strong>cajeros</strong>. Como administrador, use su
            panel de cooperativa.
          </Alert>
          {isAdmin(userRoles) && (
            <Button variant="contained" component={RouterLink} to="/admin">
              Ir a mi cooperativa
            </Button>
          )}
        </Box>
      );
    }
  }

  if (requiredRoles && !requiredRoles.some((r) => hasRole(r))) {
    return (
      <Box py={4}>
        <Alert severity="warning" sx={{ mb: 2 }}>
          No tiene permisos para esta sección.
          {userRoles.length > 0 && (
            <>
              <br />
              <small>Sus roles: {userRoles.join(', ')}</small>
            </>
          )}
        </Alert>
        {puedeUsarPanelCajero(userRoles) && (
          <Button variant="contained" component={RouterLink} to="/cajero">
            Ir a mi terminal
          </Button>
        )}
        {isAdmin(userRoles) && (
          <Button
            variant="contained"
            component={RouterLink}
            to="/admin"
            sx={{ ml: puedeUsarPanelCajero(userRoles) ? 1 : 0 }}
          >
            Ir a administración
          </Button>
        )}
      </Box>
    );
  }

  return <>{children}</>;
}
