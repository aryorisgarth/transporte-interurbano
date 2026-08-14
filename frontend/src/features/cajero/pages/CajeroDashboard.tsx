import { useEffect, useMemo, useState } from 'react';
import { Link as RouterLink, useOutletContext } from 'react-router-dom';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  CircularProgress,
  Grid,
  MenuItem,
  TextField,
  Typography,
} from '@mui/material';
import PointOfSaleIcon from '@mui/icons-material/PointOfSale';
import { SectionCard } from '@/shared/ui/SectionCard';
import { viajesMiEmpresa, type ViajeOperador } from '@/shared/api';
import { useAuth } from '@/features/auth/AuthContext';
import { fechaHoyLocal, formatearCordobas, formatearHora } from '@/shared/utils/formato';
import { CIUDADES_CORREDOR } from '@/shared/utils/corredor';
import { ROLES } from '@/shared/utils/jwt';
import { resolverTerminalCajero } from '@/shared/utils/terminalCajero';
import type { CajeroOutletContext } from '@/features/cajero/layout/CajeroLayout';

export default function CajeroDashboard() {
  const { token, hasRole, username } = useAuth();
  const { perfil } = useOutletContext<CajeroOutletContext>();
  const esSoloCajero = hasRole(ROLES.CAJERO) && !hasRole(ROLES.ADMIN_EMPRESA);

  const terminalAsignada = resolverTerminalCajero(perfil, username);

  const [viajes, setViajes] = useState<ViajeOperador[]>([]);
  const [fecha, setFecha] = useState(fechaHoyLocal());
  const [filtroOrigen, setFiltroOrigen] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const terminalFija = useMemo(() => {
    if (esSoloCajero && terminalAsignada) return terminalAsignada;
    return null;
  }, [esSoloCajero, terminalAsignada]);

  useEffect(() => {
    if (terminalFija) {
      setFiltroOrigen(terminalFija);
    }
  }, [terminalFija]);

  useEffect(() => {
    if (!token) return;

    const authToken = token;

    async function cargar() {
      setLoading(true);
      setError(null);
      try {
        const origenConsulta = esSoloCajero && terminalAsignada ? terminalAsignada : filtroOrigen || undefined;
        const v = await viajesMiEmpresa(authToken, fecha, origenConsulta);
        setViajes(v);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Error al cargar viajes');
      } finally {
        setLoading(false);
      }
    }

    cargar();
  }, [token, fecha, filtroOrigen, esSoloCajero, terminalAsignada]);

  return (
    <Box>
      {esSoloCajero && terminalAsignada && (
        <Alert severity="info" sx={{ mb: 2 }}>
          Terminal asignada: <strong>{terminalAsignada}</strong>. Solo verá salidas desde esa ciudad.
        </Alert>
      )}
      {esSoloCajero && !terminalAsignada && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          No tiene terminal asignada. Contacte al administrador para configurar su sede de venta.
        </Alert>
      )}

      <Box
        sx={{
          display: 'grid',
          gridTemplateColumns: { xs: '1fr', md: '220px 1fr' },
          gap: 2,
          mb: 3,
        }}
      >
        <SectionCard title="Flujo de venta" subtitle="3 pasos en mostrador">
          <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
            <strong>1.</strong> Elija fecha y viaje
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
            <strong>2.</strong> Seleccione asientos en el mapa
          </Typography>
          <Typography variant="body2" color="text.secondary">
            <strong>3.</strong> Confirme y entregue comprobante
          </Typography>
        </SectionCard>
        <SectionCard title="Ayuda rápida">
          <Typography variant="body2" color="text.secondary">
            Venta permitida el día anterior o el mismo día del viaje. Use Lista de pasajeros para
            imprimir manifiesto del día.
          </Typography>
        </SectionCard>
      </Box>

      <Box display="flex" gap={2} alignItems="center" flexWrap="wrap" sx={{ mb: 3 }}>
        <TextField
          type="date"
          label="Fecha"
          size="small"
          value={fecha}
          onChange={(e) => setFecha(e.target.value)}
          InputLabelProps={{ shrink: true }}
        />
        <TextField
          select
          label="Salidas desde"
          size="small"
          value={terminalFija ?? filtroOrigen}
          onChange={(e) => setFiltroOrigen(e.target.value)}
          sx={{ minWidth: 160 }}
          disabled={!!terminalFija}
          helperText={terminalFija ? 'Fijado por su terminal asignada' : undefined}
        >
          {!terminalFija && <MenuItem value="">Todas las terminales</MenuItem>}
          {CIUDADES_CORREDOR.map((c) => (
            <MenuItem key={c} value={c}>
              {c}
            </MenuItem>
          ))}
        </TextField>
        <Typography variant="body2" color="text.secondary">
          Venta permitida día anterior o mismo día del viaje
        </Typography>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {loading ? (
        <Box display="flex" justifyContent="center" py={4}>
          <CircularProgress />
        </Box>
      ) : viajes.length === 0 && !error ? (
        <Alert severity="info">
          {terminalFija
            ? `No hay salidas programadas desde ${terminalFija} para esta fecha.`
            : 'No hay viajes programados para la fecha seleccionada.'}
        </Alert>
      ) : (
        <Grid container spacing={2}>
          {viajes.map((v) => (
            <Grid item xs={12} md={6} lg={4} key={v.id}>
              <Card
                sx={{
                  height: '100%',
                  transition: 'transform 0.15s',
                  '&:hover': { transform: 'translateY(-2px)' },
                }}
              >
                <CardContent>
                  <Typography variant="overline" color="text.secondary">
                    Bus {v.busNumeroInterno}
                  </Typography>
                  <Typography variant="h6" fontWeight={700}>
                    {v.origen} → {v.destino}
                  </Typography>
                  <Typography color="text.secondary">
                    {formatearHora(String(v.horaSalida))} · {formatearCordobas(Number(v.tarifa))}
                  </Typography>
                  <Typography variant="body2" sx={{ mt: 1 }}>
                    Asientos disponibles: <strong>{v.asientosDisponibles}</strong>
                  </Typography>
                  <Button
                    variant="contained"
                    startIcon={<PointOfSaleIcon />}
                    component={RouterLink}
                    to={`/cajero/venta/${v.id}`}
                    disabled={v.asientosDisponibles === 0}
                    sx={{ mt: 2 }}
                    fullWidth
                  >
                    Vender boletos
                  </Button>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}
    </Box>
  );
}
