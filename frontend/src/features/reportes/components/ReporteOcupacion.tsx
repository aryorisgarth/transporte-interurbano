import { useEffect, useState } from 'react';
import {
  Alert,
  Box,
  CircularProgress,
  LinearProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from '@mui/material';
import { reporteOcupacion, type OcupacionViaje } from '@/shared/api';
import { fechaHoyLocal, formatearHora } from '@/shared/utils/formato';
import { SectionCard } from '@/shared/ui/SectionCard';

interface Props {
  token: string;
  empresaId: number;
  esGlobal?: boolean;
}

export function ReporteOcupacion({ token, empresaId, esGlobal = false }: Props) {
  const [fecha, setFecha] = useState(fechaHoyLocal());
  const [filas, setFilas] = useState<OcupacionViaje[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function cargar() {
      setLoading(true);
      setError(null);
      try {
        const data = await reporteOcupacion(token, fecha, esGlobal ? empresaId : undefined);
        setFilas(data);
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Error al cargar reporte');
        setFilas([]);
      } finally {
        setLoading(false);
      }
    }
    cargar();
  }, [token, fecha, empresaId, esGlobal]);

  const totalVendidos = filas.reduce((s, f) => s + f.asientosVendidos, 0);
  const totalCapacidad = filas.reduce((s, f) => s + f.capacidadTotal, 0);
  const ocupacionGlobal =
    totalCapacidad > 0
      ? Math.round(
          (filas.reduce((s, f) => s + f.asientosVendidos + f.asientosReservados, 0) /
            totalCapacidad) *
            100
        )
      : 0;

  return (
    <Box>
      <SectionCard
        title="Ocupación por viaje"
        subtitle="Asientos vendidos y reservados según la fecha del viaje"
      >
        <Box display="flex" flexWrap="wrap" gap={2} alignItems="center" mb={2}>
          <TextField
            type="date"
            label="Fecha"
            size="small"
            value={fecha}
            onChange={(e) => setFecha(e.target.value)}
            InputLabelProps={{ shrink: true }}
          />
          {filas.length > 0 && (
            <Typography variant="body2" color="text.secondary" sx={{ ml: 'auto' }}>
              {filas.length} viaje(s) · {totalVendidos} vendidos · ocupación media{' '}
              <strong>{ocupacionGlobal}%</strong>
            </Typography>
          )}
        </Box>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        {loading ? (
          <Box py={4} display="flex" justifyContent="center">
            <CircularProgress />
          </Box>
        ) : filas.length === 0 ? (
          <Alert severity="info">No hay viajes para la fecha seleccionada.</Alert>
        ) : (
          <TableContainer>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Hora</TableCell>
                  <TableCell>Ruta</TableCell>
                  <TableCell>Bus</TableCell>
                  <TableCell align="right">Vendidos</TableCell>
                  <TableCell align="right">Reservados</TableCell>
                  <TableCell align="right">Libres</TableCell>
                  <TableCell>Ocupación</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {filas.map((f) => (
                  <TableRow key={f.viajeId} hover>
                    <TableCell>{formatearHora(f.horaSalida)}</TableCell>
                    <TableCell>
                      {f.origen} → {f.destino}
                    </TableCell>
                    <TableCell>
                      {f.busNumeroInterno}{' '}
                      <Typography component="span" variant="caption" color="text.secondary">
                        ({f.busPlaca})
                      </Typography>
                    </TableCell>
                    <TableCell align="right">{f.asientosVendidos}</TableCell>
                    <TableCell align="right">{f.asientosReservados}</TableCell>
                    <TableCell align="right">{f.asientosDisponibles}</TableCell>
                    <TableCell sx={{ minWidth: 160 }}>
                      <Box display="flex" alignItems="center" gap={1}>
                        <LinearProgress
                          variant="determinate"
                          value={Math.min(Number(f.porcentajeOcupacion), 100)}
                          sx={{ flexGrow: 1, height: 8, borderRadius: 1 }}
                          color={
                            Number(f.porcentajeOcupacion) >= 80
                              ? 'success'
                              : Number(f.porcentajeOcupacion) >= 50
                                ? 'primary'
                                : 'inherit'
                          }
                        />
                        <Typography variant="body2" fontWeight={600}>
                          {f.porcentajeOcupacion}%
                        </Typography>
                      </Box>
                      <Typography variant="caption" color="text.secondary">
                        {f.asientosVendidos + f.asientosReservados}/{f.capacidadTotal}
                      </Typography>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </SectionCard>
    </Box>
  );
}
