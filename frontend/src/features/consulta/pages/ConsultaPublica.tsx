import { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  CircularProgress,
  Grid,
  IconButton,
  LinearProgress,
  MenuItem,
  TextField,
  Tooltip,
  Typography,
} from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import SwapHorizIcon from '@mui/icons-material/SwapHoriz';
import { buscarViajes, type ViajeDisponible } from '@/shared/api';
import { EmpresaAvatar } from '@/shared/maps/MapaRuta';
import { PageHeader } from '@/shared/ui/PageHeader';
import { SectionCard } from '@/shared/ui/SectionCard';
import { fechaHoyLocal, formatearCordobas, formatearHora } from '@/shared/utils/formato';

const CIUDADES = ['Bluefields', 'Managua'];

export default function ConsultaPublica() {
  const navigate = useNavigate();
  const [origen, setOrigen] = useState('Bluefields');
  const [destino, setDestino] = useState('Managua');
  const [fecha, setFecha] = useState(fechaHoyLocal);
  const [viajes, setViajes] = useState<ViajeDisponible[]>([]);
  const [loading, setLoading] = useState(true);
  const [buscado, setBuscado] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const ejecutarBusqueda = useCallback(async () => {
    if (origen === destino) {
      setError('El origen y el destino deben ser diferentes');
      setViajes([]);
      setBuscado(true);
      return;
    }

    setLoading(true);
    setError(null);
    setBuscado(true);
    try {
      const data = await buscarViajes(origen, destino, fecha);
      setViajes(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al buscar viajes');
      setViajes([]);
    } finally {
      setLoading(false);
    }
  }, [origen, destino, fecha]);

  useEffect(() => {
    ejecutarBusqueda();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps -- carga inicial

  function handleBuscar(e: React.FormEvent) {
    e.preventDefault();
    ejecutarBusqueda();
  }

  function intercambiarRuta() {
    setOrigen(destino);
    setDestino(origen);
  }

  return (
    <Box>
      <PageHeader
        title="Consulta de viajes"
        subtitle="Horarios y cupos disponibles. La venta es presencial en terminal (día anterior o mismo día del viaje)."
      />

      <SectionCard title="Buscar salidas" subtitle={`${origen} → ${destino}`}>
        <Box component="form" onSubmit={handleBuscar}>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} sm={3}>
              <TextField
                select
                fullWidth
                label="Origen"
                value={origen}
                onChange={(e) => setOrigen(e.target.value)}
              >
                {CIUDADES.map((o) => (
                  <MenuItem key={o} value={o}>
                    {o}
                  </MenuItem>
                ))}
              </TextField>
            </Grid>
            <Grid item xs={12} sm="auto" sx={{ textAlign: 'center' }}>
              <Tooltip title="Intercambiar origen y destino">
                <IconButton onClick={intercambiarRuta} aria-label="Intercambiar ruta">
                  <SwapHorizIcon />
                </IconButton>
              </Tooltip>
            </Grid>
            <Grid item xs={12} sm={3}>
              <TextField
                select
                fullWidth
                label="Destino"
                value={destino}
                onChange={(e) => setDestino(e.target.value)}
              >
                {CIUDADES.map((d) => (
                  <MenuItem key={d} value={d}>
                    {d}
                  </MenuItem>
                ))}
              </TextField>
            </Grid>
            <Grid item xs={12} sm={2}>
              <TextField
                fullWidth
                type="date"
                label="Fecha"
                InputLabelProps={{ shrink: true }}
                value={fecha}
                onChange={(e) => setFecha(e.target.value)}
                inputProps={{ min: fechaHoyLocal() }}
              />
            </Grid>
            <Grid item xs={12} sm={2}>
              <Button
                type="submit"
                variant="contained"
                fullWidth
                size="large"
                startIcon={loading ? <CircularProgress size={20} color="inherit" /> : <SearchIcon />}
                disabled={loading}
              >
                Buscar
              </Button>
            </Grid>
          </Grid>
        </Box>
      </SectionCard>

      {error && (
        <Alert severity="error" sx={{ mb: 2, mt: 2 }}>
          {error}
        </Alert>
      )}

      {loading && <LinearProgress sx={{ mb: 2, mt: 2 }} />}

      {buscado && !loading && !error && viajes.length === 0 && (
        <Alert severity="info" sx={{ mt: 2 }}>
          No hay viajes programados para {origen} → {destino} el {fecha}.
        </Alert>
      )}

      <Grid container spacing={2} sx={{ mt: 1 }}>
        {viajes.map((v) => {
          const ocupacion =
            v.capacidadTotal > 0
              ? ((v.capacidadTotal - v.asientosDisponibles) / v.capacidadTotal) * 100
              : 0;

          return (
            <Grid item xs={12} md={6} key={v.viajeId}>
              <Card
                sx={{
                  height: '100%',
                  transition: 'transform 0.15s',
                  '&:hover': { transform: 'translateY(-2px)' },
                }}
              >
                <CardContent>
                  <Box display="flex" alignItems="center" gap={1.5} mb={1}>
                    <EmpresaAvatar nombre={v.empresaNombre} logoUrl={v.empresaLogoUrl} />
                    <Typography variant="h6" fontWeight={700}>
                      {v.empresaNombre}
                    </Typography>
                  </Box>
                  <Typography color="text.secondary" variant="body2">
                    {origen} → {destino}
                  </Typography>
                  <Typography color="text.secondary">
                    Salida: {formatearHora(v.horaSalida)}
                  </Typography>
                  <Typography sx={{ mt: 1 }} fontWeight={600}>
                    {formatearCordobas(v.tarifa)} por boleto
                  </Typography>
                  <Typography variant="body2" sx={{ mt: 1 }}>
                    Cupos: {v.asientosDisponibles} / {v.capacidadTotal}
                  </Typography>
                  <LinearProgress
                    variant="determinate"
                    value={ocupacion}
                    color={v.asientosDisponibles === 0 ? 'error' : 'primary'}
                    sx={{ mt: 1, mb: 2, height: 6, borderRadius: 1 }}
                  />
                  <Button
                    variant="contained"
                    disabled={v.asientosDisponibles === 0}
                    onClick={() => navigate(`/consulta/viaje/${v.viajeId}`)}
                    fullWidth
                  >
                    {v.asientosDisponibles === 0 ? 'Agotado' : 'Ver asientos'}
                  </Button>
                </CardContent>
              </Card>
            </Grid>
          );
        })}
      </Grid>
    </Box>
  );
}
