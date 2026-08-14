import { useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  ButtonGroup,
  CircularProgress,
  Grid,
  LinearProgress,
  Tab,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Tabs,
  TextField,
  Typography,
} from '@mui/material';
import DownloadIcon from '@mui/icons-material/Download';
import AccountBalanceWalletIcon from '@mui/icons-material/AccountBalanceWallet';
import ConfirmationNumberIcon from '@mui/icons-material/ConfirmationNumber';
import LuggageIcon from '@mui/icons-material/Luggage';
import PointOfSaleIcon from '@mui/icons-material/PointOfSale';
import { reporteIngresos, type IngresosReporte } from '@/shared/api';
import { exportarCsv } from '@/shared/utils/exportCsv';
import { fechaHoyLocal, formatearCordobas, formatearHora } from '@/shared/utils/formato';
import { SectionCard } from '@/shared/ui/SectionCard';

import type { ReactNode } from 'react';

interface Props {
  token: string;
  empresaId: number;
  esGlobal?: boolean;
}

type Preset = 'hoy' | '7d' | '30d';

function restarDias(fecha: string, dias: number): string {
  const d = new Date(`${fecha}T12:00:00`);
  d.setDate(d.getDate() - dias);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function formatearFechaCorta(fecha: string): string {
  return new Date(`${fecha}T12:00:00`).toLocaleDateString('es-NI', {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
  });
}

function formatearFechaHora(iso: string): string {
  if (!iso) return '—';
  const d = new Date(iso);
  return d.toLocaleString('es-NI', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function StatCard({
  label,
  value,
  icon,
  accent,
}: {
  label: string;
  value: string;
  icon: ReactNode;
  accent: string;
}) {
  return (
    <SectionCard noPadding>
      <Box sx={{ p: 2.5, display: 'flex', gap: 2, alignItems: 'flex-start' }}>
        <Box
          sx={{
            width: 44,
            height: 44,
            borderRadius: 2,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            bgcolor: `${accent}18`,
            color: accent,
            flexShrink: 0,
          }}
        >
          {icon}
        </Box>
        <Box>
          <Typography variant="body2" color="text.secondary" fontWeight={600}>
            {label}
          </Typography>
          <Typography variant="h5" fontWeight={800} sx={{ mt: 0.25, lineHeight: 1.2 }}>
            {value}
          </Typography>
        </Box>
      </Box>
    </SectionCard>
  );
}

export function ReporteIngresos({ token, empresaId, esGlobal = false }: Props) {
  const hoy = fechaHoyLocal();
  const [desde, setDesde] = useState(hoy);
  const [hasta, setHasta] = useState(hoy);
  const [preset, setPreset] = useState<Preset>('hoy');
  const [subTab, setSubTab] = useState(0);
  const [data, setData] = useState<IngresosReporte | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function aplicarPreset(p: Preset) {
    setPreset(p);
    const fin = fechaHoyLocal();
    setHasta(fin);
    if (p === 'hoy') setDesde(fin);
    else if (p === '7d') setDesde(restarDias(fin, 6));
    else setDesde(restarDias(fin, 29));
  }

  useEffect(() => {
    async function cargar() {
      setLoading(true);
      setError(null);
      try {
        const reporte = await reporteIngresos(
          token,
          desde,
          hasta,
          esGlobal ? empresaId : undefined
        );
        setData(reporte);
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Error al cargar ingresos');
        setData(null);
      } finally {
        setLoading(false);
      }
    }
    cargar();
  }, [token, desde, hasta, empresaId, esGlobal]);

  const pctBoletos = useMemo(() => {
    if (!data?.resumen.totalIngresos) return 0;
    return Math.round(
      (data.resumen.subtotalBoletos / data.resumen.totalIngresos) * 100
    );
  }, [data]);

  function exportarDetalle() {
    if (!data) return;
    exportarCsv(
      `ingresos-${data.desde}-${data.hasta}.csv`,
      [
        'Código',
        'Fecha venta',
        'Viaje',
        'Fecha viaje',
        'Hora',
        'Cajero',
        'Terminal cajero',
        'Boletos',
        'Subtotal boletos',
        'Equipaje',
        'Total',
      ],
      data.ventas.map((v) => [
        v.codigo,
        formatearFechaHora(v.fechaVenta),
        `${v.origen} → ${v.destino}`,
        v.fechaViaje,
        formatearHora(v.horaSalida),
        v.operadorNombre,
        v.operadorSede,
        v.cantidadBoletos,
        v.subtotalBoletos,
        v.subtotalEquipaje,
        v.total,
      ])
    );
  }

  const resumen = data?.resumen;
  const sinDatos = !loading && data && resumen?.cantidadVentas === 0;

  return (
    <Box>
      <SectionCard
        title="Ingresos por ventas"
        subtitle="Ventas completadas agrupadas por fecha del viaje (no contabilidad formal)"
      >
        <Box display="flex" flexWrap="wrap" gap={2} alignItems="center" mb={2}>
          <ButtonGroup size="small" variant="outlined">
            <Button
              variant={preset === 'hoy' ? 'contained' : 'outlined'}
              onClick={() => aplicarPreset('hoy')}
            >
              Hoy
            </Button>
            <Button
              variant={preset === '7d' ? 'contained' : 'outlined'}
              onClick={() => aplicarPreset('7d')}
            >
              7 días
            </Button>
            <Button
              variant={preset === '30d' ? 'contained' : 'outlined'}
              onClick={() => aplicarPreset('30d')}
            >
              30 días
            </Button>
          </ButtonGroup>
          <TextField
            type="date"
            label="Desde"
            size="small"
            value={desde}
            onChange={(e) => {
              setPreset('hoy');
              setDesde(e.target.value);
            }}
            InputLabelProps={{ shrink: true }}
          />
          <TextField
            type="date"
            label="Hasta"
            size="small"
            value={hasta}
            onChange={(e) => {
              setPreset('hoy');
              setHasta(e.target.value);
            }}
            InputLabelProps={{ shrink: true }}
          />
          {data && data.ventas.length > 0 && (
            <Button
              size="small"
              variant="outlined"
              startIcon={<DownloadIcon />}
              onClick={exportarDetalle}
              sx={{ ml: 'auto' }}
            >
              Exportar CSV
            </Button>
          )}
        </Box>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        {loading ? (
          <Box py={6} display="flex" justifyContent="center">
            <CircularProgress />
          </Box>
        ) : resumen ? (
          <>
            <Grid container spacing={2} sx={{ mb: 3 }}>
              <Grid item xs={12} sm={6} md={3}>
                <StatCard
                  label="Ingresos totales"
                  value={formatearCordobas(resumen.totalIngresos)}
                  icon={<AccountBalanceWalletIcon />}
                  accent="#0f766e"
                />
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <StatCard
                  label="Boletos"
                  value={formatearCordobas(resumen.subtotalBoletos)}
                  icon={<ConfirmationNumberIcon />}
                  accent="#0369a1"
                />
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <StatCard
                  label="Equipaje extra"
                  value={formatearCordobas(resumen.subtotalEquipaje)}
                  icon={<LuggageIcon />}
                  accent="#7c3aed"
                />
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <StatCard
                  label="Ventas / ticket prom."
                  value={`${resumen.cantidadVentas} · ${formatearCordobas(resumen.ticketPromedio)}`}
                  icon={<PointOfSaleIcon />}
                  accent="#15803d"
                />
              </Grid>
            </Grid>

            {resumen.totalIngresos > 0 && (
              <Box sx={{ mb: 3, maxWidth: 480 }}>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  Composición del ingreso
                </Typography>
                <Box display="flex" alignItems="center" gap={1} mb={0.5}>
                  <LinearProgress
                    variant="determinate"
                    value={pctBoletos}
                    sx={{ flex: 1, height: 10, borderRadius: 1 }}
                  />
                  <Typography variant="caption" fontWeight={600}>
                    {pctBoletos}% boletos
                  </Typography>
                </Box>
                <Typography variant="caption" color="text.secondary">
                  {resumen.cantidadBoletos} boletos vendidos en el período
                </Typography>
              </Box>
            )}

            {sinDatos ? (
              <Alert severity="info">
                No hay ventas completadas en el período seleccionado.
              </Alert>
            ) : (
              <>
                <Tabs
                  value={subTab}
                  onChange={(_, v) => setSubTab(v)}
                  sx={{ mb: 2, borderBottom: 1, borderColor: 'divider' }}
                >
                  <Tab label="Por día" />
                  <Tab label="Por viaje" />
                  <Tab label="Por cajero" />
                  <Tab label="Por terminal" />
                  <Tab label="Detalle ventas" />
                </Tabs>

                {subTab === 0 && (
                  <TableContainer>
                    <Table size="small">
                      <TableHead>
                        <TableRow>
                          <TableCell>Fecha</TableCell>
                          <TableCell align="right">Ventas</TableCell>
                          <TableCell align="right">Boletos</TableCell>
                          <TableCell align="right">Boletos C$</TableCell>
                          <TableCell align="right">Equipaje C$</TableCell>
                          <TableCell align="right">Total C$</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {data.porDia.map((f) => (
                          <TableRow key={f.fecha}>
                            <TableCell>{formatearFechaCorta(f.fecha)}</TableCell>
                            <TableCell align="right">{f.cantidadVentas}</TableCell>
                            <TableCell align="right">{f.cantidadBoletos}</TableCell>
                            <TableCell align="right">
                              {formatearCordobas(f.subtotalBoletos)}
                            </TableCell>
                            <TableCell align="right">
                              {formatearCordobas(f.subtotalEquipaje)}
                            </TableCell>
                            <TableCell align="right" sx={{ fontWeight: 700 }}>
                              {formatearCordobas(f.totalIngresos)}
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                )}

                {subTab === 1 && (
                  <TableContainer>
                    <Table size="small">
                      <TableHead>
                        <TableRow>
                          <TableCell>Fecha</TableCell>
                          <TableCell>Hora</TableCell>
                          <TableCell>Ruta</TableCell>
                          <TableCell>Bus</TableCell>
                          <TableCell align="right">Ventas</TableCell>
                          <TableCell align="right">Total C$</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {data.porViaje.map((f) => (
                          <TableRow key={f.viajeId}>
                            <TableCell>{formatearFechaCorta(f.fecha)}</TableCell>
                            <TableCell>{formatearHora(f.horaSalida)}</TableCell>
                            <TableCell>
                              {f.origen} → {f.destino}
                            </TableCell>
                            <TableCell>{f.busNumeroInterno}</TableCell>
                            <TableCell align="right">{f.cantidadVentas}</TableCell>
                            <TableCell align="right" sx={{ fontWeight: 700 }}>
                              {formatearCordobas(f.totalIngresos)}
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                )}

                {subTab === 2 && (
                  <TableContainer>
                    <Table size="small">
                      <TableHead>
                        <TableRow>
                          <TableCell>Cajero</TableCell>
                          <TableCell>Terminal</TableCell>
                          <TableCell align="right">Ventas</TableCell>
                          <TableCell align="right">Boletos</TableCell>
                          <TableCell align="right">Total C$</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {data.porCajero.map((f) => (
                          <TableRow key={f.operadorId}>
                            <TableCell>{f.operadorNombre}</TableCell>
                            <TableCell>{f.sede}</TableCell>
                            <TableCell align="right">{f.cantidadVentas}</TableCell>
                            <TableCell align="right">{f.cantidadBoletos}</TableCell>
                            <TableCell align="right" sx={{ fontWeight: 700 }}>
                              {formatearCordobas(f.totalIngresos)}
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                )}

                {subTab === 3 && (
                  <TableContainer>
                    <Table size="small">
                      <TableHead>
                        <TableRow>
                          <TableCell>Terminal de salida</TableCell>
                          <TableCell align="right">Ventas</TableCell>
                          <TableCell align="right">Boletos</TableCell>
                          <TableCell align="right">Total C$</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {data.porTerminal.map((f) => (
                          <TableRow key={f.terminal}>
                            <TableCell>{f.terminal}</TableCell>
                            <TableCell align="right">{f.cantidadVentas}</TableCell>
                            <TableCell align="right">{f.cantidadBoletos}</TableCell>
                            <TableCell align="right" sx={{ fontWeight: 700 }}>
                              {formatearCordobas(f.totalIngresos)}
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                )}

                {subTab === 4 && (
                  <TableContainer id="reporte-ingresos-detalle">
                    <Table size="small">
                      <TableHead>
                        <TableRow>
                          <TableCell>Código</TableCell>
                          <TableCell>Fecha venta</TableCell>
                          <TableCell>Viaje</TableCell>
                          <TableCell>Cajero</TableCell>
                          <TableCell align="right">Boletos</TableCell>
                          <TableCell align="right">Total C$</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {data.ventas.map((v) => (
                          <TableRow key={v.ventaId}>
                            <TableCell sx={{ fontFamily: 'monospace', fontSize: '0.8rem' }}>
                              {v.codigo}
                            </TableCell>
                            <TableCell>{formatearFechaHora(v.fechaVenta)}</TableCell>
                            <TableCell>
                              {formatearFechaCorta(v.fechaViaje)}{' '}
                              {formatearHora(v.horaSalida)} · {v.origen}→{v.destino}
                            </TableCell>
                            <TableCell>
                              {v.operadorNombre}
                              <Typography variant="caption" display="block" color="text.secondary">
                                {v.operadorSede}
                              </Typography>
                            </TableCell>
                            <TableCell align="right">{v.cantidadBoletos}</TableCell>
                            <TableCell align="right" sx={{ fontWeight: 700 }}>
                              {formatearCordobas(v.total)}
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                )}
              </>
            )}
          </>
        ) : null}
      </SectionCard>
    </Box>
  );
}
