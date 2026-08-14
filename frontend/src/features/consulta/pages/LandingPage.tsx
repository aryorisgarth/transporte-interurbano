import { Link as RouterLink } from 'react-router-dom';
import { Box, Button, Card, CardContent, Grid, Stack, Typography } from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import StorefrontIcon from '@mui/icons-material/Storefront';
import BusinessIcon from '@mui/icons-material/Business';
import HubIcon from '@mui/icons-material/Hub';
import LoginIcon from '@mui/icons-material/Login';
import ArrowForwardIcon from '@mui/icons-material/ArrowForward';
import { EmpresaAvatar } from '@/shared/maps/MapaRuta';
import { PageHeader } from '@/shared/ui/PageHeader';
import { gradientHero } from '@/shared/theme';

const EMPRESAS = [
  {
    nombre: 'Wendelyn Transporte',
    logoUrl: 'https://ui-avatars.com/api/?name=WT&background=0f766e&color=fff&size=128',
  },
  {
    nombre: 'Martínez Líneas',
    logoUrl: 'https://ui-avatars.com/api/?name=ML&background=0369a1&color=fff&size=128',
  },
];

const ROLES_PUBLIC = [
  {
    icon: <SearchIcon sx={{ fontSize: 36 }} />,
    color: '#0369a1',
    title: 'Pasajero',
    desc: 'Consulta horarios y cupos sin cuenta. La compra es presencial en terminal.',
    cta: { to: '/consulta', label: 'Consultar viajes' },
  },
  {
    icon: <StorefrontIcon sx={{ fontSize: 36 }} />,
    color: '#0f766e',
    title: 'Cajero',
    desc: 'Venta en mostrador, terminal fija, manifiesto de su sede.',
    cta: { to: '/acceso/login', label: 'Entrar como cajero', state: { from: '/cajero' } },
  },
  {
    icon: <BusinessIcon sx={{ fontSize: 36 }} />,
    color: '#7c3aed',
    title: 'Admin empresa',
    desc: 'Flota, viajes, operadores y reportes de su cooperativa.',
    cta: { to: '/acceso/login', label: 'Entrar como admin', state: { from: '/admin' } },
  },
  {
    icon: <HubIcon sx={{ fontSize: 36 }} />,
    color: '#0c4a6e',
    title: 'Plataforma',
    desc: 'Multi-tenant: cooperativas, admins de empresa y métricas globales.',
    cta: { to: '/acceso/login', label: 'Admin global', state: { from: '/admin' } },
  },
];

export default function LandingPage() {
  return (
    <Box>
      <PageHeader
        title="Bluefields ↔ Managua"
        subtitle="Plataforma multi-cooperativa: consulta pública, venta en terminal y administración por roles."
        actions={
          <Button
            variant="contained"
            color="secondary"
            size="large"
            component={RouterLink}
            to="/consulta"
            startIcon={<SearchIcon />}
            sx={{ bgcolor: '#fff', color: 'primary.dark', '&:hover': { bgcolor: '#f0fdfa' } }}
          >
            Consultar ahora
          </Button>
        }
      />

      <Grid container spacing={2.5} sx={{ mb: 4 }}>
        {ROLES_PUBLIC.map((r) => (
          <Grid item xs={12} sm={6} md={3} key={r.title}>
            <Card
              sx={{
                height: '100%',
                transition: 'transform 0.2s, box-shadow 0.2s',
                '&:hover': { transform: 'translateY(-4px)', boxShadow: 4 },
              }}
            >
              <CardContent>
                <Box sx={{ color: r.color, mb: 1.5 }}>{r.icon}</Box>
                <Typography variant="h6" fontWeight={700} gutterBottom>
                  {r.title}
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2, minHeight: 56 }}>
                  {r.desc}
                </Typography>
                <Button
                  component={RouterLink}
                  to={r.cta.to}
                  state={r.cta.state}
                  endIcon={<ArrowForwardIcon />}
                  size="small"
                >
                  {r.cta.label}
                </Button>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Typography variant="h5" fontWeight={700} gutterBottom>
        Cooperativas en la ruta
      </Typography>
      <Grid container spacing={2} sx={{ mb: 4 }}>
        {EMPRESAS.map((emp) => (
          <Grid item xs={12} sm={6} key={emp.nombre}>
            <Card variant="outlined">
              <CardContent sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <EmpresaAvatar nombre={emp.nombre} logoUrl={emp.logoUrl} size={52} />
                <Box>
                  <Typography fontWeight={700}>{emp.nombre}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Corredor interurbano · datos aislados por tenant
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Card sx={{ background: gradientHero, color: '#fff' }}>
        <CardContent>
          <Stack direction={{ xs: 'column', sm: 'row' }} alignItems="center" spacing={2}>
            <Box flex={1}>
              <Typography variant="h6" fontWeight={700} gutterBottom>
                ¿Personal de terminal o administración?
              </Typography>
              <Typography sx={{ opacity: 0.9 }}>Inicie sesión con su usuario asignado.</Typography>
            </Box>
            <Button
              variant="outlined"
              component={RouterLink}
              to="/acceso/login"
              startIcon={<LoginIcon />}
              sx={{ color: '#fff', borderColor: 'rgba(255,255,255,0.5)', whiteSpace: 'nowrap' }}
            >
              Iniciar sesión
            </Button>
          </Stack>
        </CardContent>
      </Card>
    </Box>
  );
}
