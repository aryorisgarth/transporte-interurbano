import {
  AppBar,
  Avatar,
  Box,
  Button,
  Chip,
  Container,
  Stack,
  Toolbar,
  Typography,
} from '@mui/material';
import DirectionsBusFilledIcon from '@mui/icons-material/DirectionsBusFilled';
import LoginIcon from '@mui/icons-material/Login';
import LogoutIcon from '@mui/icons-material/Logout';
import { Link, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '@/features/auth/AuthContext';
import {
  ROLES,
  esAdminEmpresa,
  esAdminGlobal,
  extractRolesFromToken,
  isAdmin,
  puedeUsarPanelCajero,
} from '@/shared/utils/jwt';
import { primaryRoleLabel } from '@/shared/utils/rolesUi';
import { RoleBadge } from '@/shared/ui/RoleBadge';

export function Layout() {
  const { isAuthenticated, username, logout, token, roles } = useAuth();
  const location = useLocation();
  const path = location.pathname;
  const fullBleed = path.startsWith('/admin') || path.startsWith('/cajero');

  const effectiveRoles = token ? extractRolesFromToken(token) : roles;
  const enAreaOperativa = path.startsWith('/cajero') || path.startsWith('/admin');
  const enPublico = path === '/' || path.startsWith('/consulta') || path.startsWith('/acceso');

  const panelAdmin = isAdmin(effectiveRoles);
  const panelCajero = puedeUsarPanelCajero(effectiveRoles);

  const labelPanelAdmin = esAdminGlobal(effectiveRoles)
    ? 'Plataforma'
    : esAdminEmpresa(effectiveRoles)
      ? 'Mi cooperativa'
      : 'Administración';

  const navLink = (to: string, label: string, active: boolean, opts?: { muted?: boolean }) => (
    <Button
      component={Link}
      to={to}
      color="inherit"
      size="small"
      sx={{
        opacity: active ? 1 : opts?.muted ? 0.72 : 0.88,
        fontWeight: active ? 700 : 500,
        bgcolor: active ? 'rgba(255,255,255,0.16)' : 'transparent',
        '&:hover': { bgcolor: 'rgba(255,255,255,0.12)' },
      }}
    >
      {label}
    </Button>
  );

  const roleBadgeKey = effectiveRoles.includes(ROLES.ADMIN_GENERAL)
    ? ROLES.ADMIN_GENERAL
    : effectiveRoles.includes(ROLES.ADMIN_EMPRESA)
      ? ROLES.ADMIN_EMPRESA
      : ROLES.CAJERO;

  return (
    <Box sx={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', ...(fullBleed && { height: '100vh', overflow: 'hidden' }) }}>
      {!fullBleed && (
      <AppBar
        position="sticky"
        elevation={0}
        sx={{
          bgcolor: enAreaOperativa ? 'primary.dark' : 'primary.main',
          borderBottom: '1px solid rgba(255,255,255,0.12)',
        }}
      >
        <Toolbar sx={{ gap: 0.5, flexWrap: 'wrap', py: 0.75, minHeight: 56 }}>
          <DirectionsBusFilledIcon sx={{ mr: 0.25, display: { xs: 'none', sm: 'block' } }} />
          <Typography
            variant="h6"
            component={Link}
            to={isAuthenticated && panelAdmin ? '/admin' : isAuthenticated && panelCajero ? '/cajero' : '/'}
            sx={{
              color: 'inherit',
              textDecoration: 'none',
              fontWeight: 800,
              letterSpacing: -0.3,
              mr: { md: 1.5 },
              fontSize: { xs: '1rem', sm: '1.15rem' },
            }}
          >
            Transporte B–M
          </Typography>

          <Stack
            direction="row"
            spacing={0.25}
            alignItems="center"
            sx={{ flexGrow: 1, flexWrap: 'wrap' }}
          >
            {!isAuthenticated && (
              <>
                {navLink('/', 'Inicio', path === '/')}
                {navLink('/consulta', 'Consultar viajes', path.startsWith('/consulta'))}
              </>
            )}

            {isAuthenticated && panelCajero && (
              <>
                {navLink('/cajero', 'Mi terminal', path.startsWith('/cajero'))}
                {navLink('/consulta', 'Horarios públicos', path.startsWith('/consulta'), { muted: true })}
              </>
            )}

            {isAuthenticated && panelAdmin && !panelCajero && (
              <>
                {navLink('/admin', labelPanelAdmin, path.startsWith('/admin'))}
                {navLink('/consulta', 'Consulta pública', path.startsWith('/consulta'), { muted: true })}
              </>
            )}

            {isAuthenticated && !panelAdmin && !panelCajero && (
              <>
                {navLink('/', 'Inicio', path === '/')}
                {navLink('/consulta', 'Consultar', path.startsWith('/consulta'))}
              </>
            )}
          </Stack>

          {isAuthenticated ? (
            <Stack direction="row" alignItems="center" spacing={0.75}>
              <Box sx={{ display: { xs: 'none', lg: 'block' } }}>
                <RoleBadge role={roleBadgeKey} inverted />
              </Box>
              <Chip
                size="small"
                avatar={
                  <Avatar sx={{ width: 24, height: 24, fontSize: 12 }}>
                    {(username ?? 'U')[0].toUpperCase()}
                  </Avatar>
                }
                label={
                  <Box component="span" sx={{ display: { xs: 'none', sm: 'inline' } }}>
                    {username}
                  </Box>
                }
                sx={{ bgcolor: 'rgba(255,255,255,0.15)', color: '#fff', border: 'none' }}
              />
              <Button
                color="inherit"
                size="small"
                onClick={logout}
                startIcon={<LogoutIcon sx={{ display: { xs: 'none', sm: 'block' } }} />}
              >
                Salir
              </Button>
            </Stack>
          ) : (
            <Button
              variant="contained"
              color="secondary"
              component={Link}
              to="/acceso/login"
              size="small"
              startIcon={<LoginIcon />}
              sx={{
                bgcolor: 'rgba(255,255,255,0.95)',
                color: 'primary.dark',
                '&:hover': { bgcolor: '#fff' },
                boxShadow: 'none',
              }}
            >
              Acceso personal
            </Button>
          )}
        </Toolbar>

        {isAuthenticated && enAreaOperativa && (
          <Box
            sx={{
              px: 2,
              pb: 0.75,
              pt: 0,
              display: { xs: 'block', md: 'none' },
            }}
          >
            <Typography variant="caption" sx={{ opacity: 0.85 }}>
              {primaryRoleLabel(effectiveRoles)}
              {panelCajero && path.startsWith('/cajero') && ' · Venta en terminal'}
              {panelAdmin && path.startsWith('/admin') && ' · Gestión de cooperativa'}
            </Typography>
          </Box>
        )}

        {!isAuthenticated && enPublico && (
          <Box sx={{ px: 2, pb: 1, display: { xs: 'none', md: 'block' } }}>
            <Typography variant="caption" sx={{ opacity: 0.8 }}>
              Pasajeros: consulte horarios sin cuenta · Personal: use Acceso personal
            </Typography>
          </Box>
        )}
      </AppBar>
      )}

      {fullBleed ? (
        <Box component="main" sx={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}>
          <Outlet />
        </Box>
      ) : (
        <>
          <Container maxWidth="lg" sx={{ py: { xs: 2.5, md: 4 }, flex: 1 }}>
            <Outlet />
          </Container>

          <Box
            component="footer"
            sx={{
              py: 2.5,
              px: 2,
              textAlign: 'center',
              color: 'text.secondary',
              borderTop: 1,
              borderColor: 'divider',
              bgcolor: 'background.paper',
              fontSize: '0.875rem',
            }}
          >
            Sistema de Gestión de Transporte Interurbano · Bluefields – Managua
            <Typography variant="caption" display="block" sx={{ mt: 0.5, opacity: 0.75 }}>
              Multi-tenant · Venta en terminal · Demo académica
            </Typography>
          </Box>
        </>
      )}
    </Box>
  );
}
