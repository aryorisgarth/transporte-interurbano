import { useState } from 'react';
import { Link as RouterLink, Navigate, useLocation, useNavigate } from 'react-router-dom';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  CircularProgress,
  Link,
  TextField,
  Typography,
} from '@mui/material';
import DirectionsBusFilledIcon from '@mui/icons-material/DirectionsBusFilled';
import LoginIcon from '@mui/icons-material/Login';
import { loginKeycloak } from '@/shared/api';
import { useAuth } from '@/features/auth/AuthContext';
import { USE_MOCK, DEMO_USER } from '@/shared/config/env';
import { extractRolesFromToken, rutaInicio } from '@/shared/utils/jwt';

const INTENT_LABEL: Record<string, string> = {
  cajero: 'Terminal · venta en mostrador',
  admin: 'Administración de cooperativa',
};

export default function LoginPersonal() {
  const { isAuthenticated, login, roles } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const from = (location.state as { from?: string })?.from;
  const intent = from?.startsWith('/cajero') ? 'cajero' : from?.startsWith('/admin') ? 'admin' : null;

  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  if (isAuthenticated) {
    return <Navigate to={rutaInicio(roles, from)} replace />;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    const user = username.trim();
    const pass = password;
    if (!user || !pass) {
      setError('Ingrese usuario y contraseña.');
      setLoading(false);
      return;
    }
    try {
      const token = await loginKeycloak(user, pass);
      const rolesFromToken = extractRolesFromToken(token);
      if (rolesFromToken.length === 0) {
        throw new Error('No se pudieron obtener permisos. Intente de nuevo.');
      }
      login(token, user);
      navigate(rutaInicio(rolesFromToken, from), { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Usuario o contraseña incorrectos');
    } finally {
      setLoading(false);
    }
  }

  return (
    <Box className="login-page">
      <Card className="login-card" elevation={0}>
        <CardContent component="form" onSubmit={handleSubmit} className="login-card__content">
          <Box className="login-card__brand">
            <DirectionsBusFilledIcon sx={{ fontSize: 36 }} />
            <Box>
              <Typography variant="h5" fontWeight={800} lineHeight={1.2}>
                Transporte B–M
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {intent ? INTENT_LABEL[intent] : 'Acceso personal'}
              </Typography>
            </Box>
          </Box>

          {USE_MOCK && (
            <Alert severity="info" sx={{ mb: 2 }}>
              <strong>Modo demo:</strong> datos estáticos sin Keycloak ni backend. Use cualquier usuario/contraseña
              o entre directamente — sesión: {DEMO_USER.name} ({DEMO_USER.email}).
            </Alert>
          )}

          <TextField
            fullWidth
            label="Usuario"
            margin="normal"
            autoComplete="username"
            autoFocus
            value={username}
            onChange={(e) => setUsername(e.target.value)}
          />
          <TextField
            fullWidth
            type="password"
            label="Contraseña"
            margin="normal"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />

          {error && (
            <Alert severity="error" sx={{ mt: 2 }}>
              {error}
            </Alert>
          )}

          <Button
            type="submit"
            variant="contained"
            fullWidth
            size="large"
            sx={{ mt: 3 }}
            startIcon={loading ? <CircularProgress size={20} color="inherit" /> : <LoginIcon />}
            disabled={loading}
          >
            Entrar
          </Button>

          <Typography variant="body2" color="text.secondary" textAlign="center" sx={{ mt: 2.5 }}>
            <Link component={RouterLink} to="/consulta" underline="hover" color="inherit">
              Consultar horarios
            </Link>
            {' · '}
            <Link component={RouterLink} to="/" underline="hover" color="inherit">
              Inicio
            </Link>
          </Typography>
        </CardContent>
      </Card>
    </Box>
  );
}
