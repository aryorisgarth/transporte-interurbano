import { useEffect, useState } from 'react';
import { Link as RouterLink, useParams } from 'react-router-dom';
import {
  Alert,
  Box,
  Button,
  Checkbox,
  CircularProgress,
  Divider,
  FormControlLabel,
  Grid,
  Stack,
  TextField,
  Typography,
  useMediaQuery,
  useTheme,
} from '@mui/material';
import EventSeatIcon from '@mui/icons-material/EventSeat';
import {
  crearVenta,
  detalleViajeOperador,
  type DetalleViaje,
  type VentaResponse,
} from '@/shared/api';
import { ComprobanteVenta } from '@/features/cajero/components/ComprobanteVenta';
import { ReservaExcepcionalDialog } from '@/features/cajero/components/ReservaExcepcionalDialog';
import { SeatMap } from '@/shared/maps/SeatMap';
import { SectionCard } from '@/shared/ui/SectionCard';
import { useAuth } from '@/features/auth/AuthContext';
import { formatearCordobas, formatearHora } from '@/shared/utils/formato';
import { ROLES } from '@/shared/utils/jwt';

interface DatosPasajero {
  nombre: string;
  cedula: string;
  esMenor: boolean;
  edad: string;
}

export default function PanelCajero() {
  const { id } = useParams<{ id: string }>();
  const { token, hasRole } = useAuth();
  const theme = useTheme();
  const esMobile = useMediaQuery(theme.breakpoints.down('md'));
  const puedeReservar = hasRole(
    ROLES.RESERVA_EXCEPCIONAL,
    ROLES.ADMIN_EMPRESA,
    ROLES.ADMIN_GENERAL
  );

  const [detalle, setDetalle] = useState<DetalleViaje | null>(null);
  const [seleccionados, setSeleccionados] = useState<number[]>([]);
  const [modoDetallado, setModoDetallado] = useState(false);
  const [pasajeros, setPasajeros] = useState<Record<number, DatosPasajero>>({});

  const [compradorNombre, setCompradorNombre] = useState('');
  const [compradorCedula, setCompradorCedula] = useState('');
  const [compradorTelefono, setCompradorTelefono] = useState('');
  const [equipajeExtra, setEquipajeExtra] = useState(0);

  const [loading, setLoading] = useState(true);
  const [ventaLoading, setVentaLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [ventaOk, setVentaOk] = useState<VentaResponse | null>(null);
  const [mostrarComprobante, setMostrarComprobante] = useState(false);
  const [dialogReserva, setDialogReserva] = useState(false);

  async function recargarDetalle(viajeId: number) {
    if (!token) return;
    setDetalle(await detalleViajeOperador(viajeId, token));
  }

  useEffect(() => {
    if (!id || !token) return;
    setLoading(true);
    setError(null);
    detalleViajeOperador(Number(id), token)
      .then(setDetalle)
      .catch((err) => setError(err instanceof Error ? err.message : 'Error al cargar viaje'))
      .finally(() => setLoading(false));
  }, [id, token]);

  function numeroAsiento(viajeAsientoId: number) {
    return detalle?.asientos.find((a) => a.viajeAsientoId === viajeAsientoId)?.numero ?? viajeAsientoId;
  }

  function toggleAsiento(viajeAsientoId: number) {
    setSeleccionados((prev) => {
      const next = prev.includes(viajeAsientoId)
        ? prev.filter((x) => x !== viajeAsientoId)
        : [...prev, viajeAsientoId];

      if (!prev.includes(viajeAsientoId)) {
        setPasajeros((p) => ({
          ...p,
          [viajeAsientoId]: p[viajeAsientoId] ?? {
            nombre: '',
            cedula: '',
            esMenor: false,
            edad: '',
          },
        }));
      }
      return next;
    });
  }

  function updatePasajero(asientoId: number, field: keyof DatosPasajero, value: string | boolean) {
    setPasajeros((prev) => ({
      ...prev,
      [asientoId]: {
        ...(prev[asientoId] ?? { nombre: '', cedula: '', esMenor: false, edad: '' }),
        [field]: value,
      },
    }));
  }

  function cedulaValida(cedula: string): boolean {
    return cedula.trim().length >= 5;
  }

  /** Adulto responsable puede viajar sin duplicar formulario; menores usan cédula del pagador. */
  function datosPasajero(asientoId: number) {
    const p = pasajeros[asientoId] ?? { nombre: '', cedula: '', esMenor: false, edad: '' };
    let nombre = p.nombre.trim();
    let cedula = p.cedula.trim();
    const responsableNombre = compradorNombre.trim();
    const responsableCedula = compradorCedula.trim();

    if (!p.esMenor) {
      if (!nombre) nombre = responsableNombre;
      if (!cedula) cedula = responsableCedula;
    } else if (!cedula) {
      cedula = responsableCedula;
    }

    return {
      nombre,
      cedula,
      esMenor: p.esMenor,
      edad: p.esMenor && p.edad ? Number(p.edad) : undefined,
    };
  }

  function pasajerosValidos(): boolean {
    if (!modoDetallado) {
      return !!compradorNombre.trim() && cedulaValida(compradorCedula);
    }
    if (!compradorNombre.trim() || !cedulaValida(compradorCedula)) return false;
    return seleccionados.every((id) => {
      const d = datosPasajero(id);
      if (!d.nombre || !cedulaValida(d.cedula)) return false;
      if (d.esMenor && d.edad == null) return false;
      return true;
    });
  }

  function motivoFormularioInvalido(): string | null {
    if (seleccionados.length === 0) return 'Seleccione al menos un asiento.';
    if (!modoDetallado) {
      if (!compradorNombre.trim()) return 'Indique el nombre del comprador.';
      if (!cedulaValida(compradorCedula)) return 'La cédula del comprador debe tener al menos 5 caracteres.';
      return null;
    }
    if (!compradorNombre.trim()) return 'Indique el nombre del adulto responsable.';
    if (!cedulaValida(compradorCedula)) {
      return 'La cédula del responsable debe tener al menos 5 caracteres.';
    }
    for (const id of seleccionados) {
      const d = datosPasajero(id);
      const num = numeroAsiento(id);
      if (!d.nombre) return `Falta el nombre del pasajero en asiento #${num}.`;
      if (!cedulaValida(d.cedula)) {
        return d.esMenor
          ? `Indique cédula del menor o del responsable en asiento #${num}.`
          : `Indique cédula del pasajero o del responsable en asiento #${num}.`;
      }
      if (d.esMenor && d.edad == null) return `Indique la edad del menor en asiento #${num}.`;
    }
    return null;
  }

  async function handleVenta(e: React.FormEvent) {
    e.preventDefault();
    if (!detalle || seleccionados.length === 0 || !token) return;

    setVentaLoading(true);
    setError(null);
    setVentaOk(null);

    try {
      const res = await crearVenta(
        {
          viajeId: detalle.viajeId,
          compradorNombre,
          compradorCedula,
          compradorTelefono: compradorTelefono || undefined,
          viajeAsientoIds: seleccionados,
          pasajeros: modoDetallado
            ? seleccionados.map((asientoId) => {
                const d = datosPasajero(asientoId);
                return {
                  viajeAsientoId: asientoId,
                  pasajeroNombre: d.nombre,
                  pasajeroCedula: d.cedula,
                  esMenor: d.esMenor,
                  edad: d.edad,
                };
              })
            : undefined,
          equipajeExtra:
            equipajeExtra > 0
              ? { cantidad: equipajeExtra, montoUnitario: detalle.tarifaEquipajeExtra }
              : undefined,
        },
        token
      );
      setVentaOk(res);
      setMostrarComprobante(true);
      setSeleccionados([]);
      setPasajeros({});
      setCompradorNombre('');
      setCompradorCedula('');
      setCompradorTelefono('');
      setEquipajeExtra(0);
      await recargarDetalle(detalle.viajeId);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al registrar venta');
    } finally {
      setVentaLoading(false);
    }
  }

  const tarifa = detalle?.tarifa ?? 0;
  const tarifaEquipaje = detalle?.tarifaEquipajeExtra ?? 0;
  const subtotalBoletos = seleccionados.length * tarifa;
  const subtotalEquipaje = equipajeExtra > 0 ? equipajeExtra * tarifaEquipaje : 0;
  const total = subtotalBoletos + subtotalEquipaje;

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" py={6}>
        <CircularProgress />
      </Box>
    );
  }

  if (!detalle) {
    return (
      <Alert severity="error">
        {error ?? 'Viaje no encontrado'}
        {error?.includes('Acceso denegado') && <> — Solo puede vender viajes de su cooperativa.</>}
      </Alert>
    );
  }

  return (
    <Box className="cajero-venta-page">
      <Stack
        direction={{ xs: 'column', sm: 'row' }}
        alignItems={{ sm: 'center' }}
        justifyContent="space-between"
        spacing={1}
        className="cajero-venta-page__header"
      >
        <Box>
          <Typography variant="h6" fontWeight={700}>
            {detalle.origen} → {detalle.destino}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {detalle.empresaNombre} · {detalle.fecha} · {formatearHora(detalle.horaSalida)} · Bus{' '}
            {detalle.busNumeroInterno}
          </Typography>
        </Box>
        <Stack direction="row" spacing={1}>
          <Button component={RouterLink} to="/cajero" variant="outlined" size="small">
            Volver a viajes
          </Button>
          {puedeReservar && (
            <Button variant="outlined" color="secondary" size="small" onClick={() => setDialogReserva(true)}>
              Reserva excepcional
            </Button>
          )}
        </Stack>
      </Stack>

      <Box className="cajero-venta-page__grid">
        <Box className="cajero-venta-page__map">
          <SectionCard title="Seleccionar asientos" noPadding>
            <Box sx={{ p: 2 }}>
              <Box className="cajero-venta-page__bus-wrap">
                <SeatMap
                  asientos={detalle.asientos}
                  seleccionados={seleccionados}
                  onToggle={toggleAsiento}
                  modoSeleccion
                  fillContainer={false}
                  compact
                  busMarca="Yutong"
                  busFotoUrl={detalle.busFotoUrl}
                  busNumeroInterno={detalle.busNumeroInterno}
                />
              </Box>
            </Box>
          </SectionCard>
        </Box>

        <Box className="cajero-venta-page__form">
          <SectionCard title="Datos del comprador">
            <Box id="form-venta-cajero" component="form" onSubmit={handleVenta}>

              {seleccionados.length > 0 && (
                <Typography
                  variant="caption"
                  sx={{
                    display: 'block',
                    mb: 1.5,
                    px: 1,
                    py: 0.75,
                    borderRadius: 1,
                    bgcolor: 'rgba(15, 118, 110, 0.08)',
                    color: 'primary.main',
                    fontWeight: 600,
                  }}
                >
                  {seleccionados.map((id) => `#${numeroAsiento(id)}`).join(' · ')} ·{' '}
                  {formatearCordobas(total)}
                </Typography>
              )}

              {seleccionados.length === 0 && (
                <Alert severity="info" sx={{ mb: 2 }}>
                  Elija asientos en el mapa {esMobile ? 'arriba' : 'a la izquierda'}. El resumen y el botón
                  de confirmar aparecen en este panel.
                </Alert>
              )}

              <FormControlLabel
                control={
                  <Checkbox
                    checked={modoDetallado}
                    onChange={(e) => setModoDetallado(e.target.checked)}
                  />
                }
                label="Registrar cada pasajero por separado"
              />

              {!modoDetallado ? (
                <Grid container spacing={2} sx={{ mt: 0.5 }}>
                  <Grid item xs={12}>
                    <TextField
                      required
                      fullWidth
                      label="Nombre completo"
                      value={compradorNombre}
                      onChange={(e) => setCompradorNombre(e.target.value)}
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <TextField
                      required
                      fullWidth
                      label="Cédula"
                      value={compradorCedula}
                      onChange={(e) => setCompradorCedula(e.target.value)}
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Teléfono"
                      value={compradorTelefono}
                      onChange={(e) => setCompradorTelefono(e.target.value)}
                    />
                  </Grid>
                </Grid>
              ) : (
                <Box className="cajero-venta-page__form-inner" sx={{ mt: 1 }}>
                  <Alert severity="info" sx={{ mb: 2 }}>
                    Un registro por asiento. Si el adulto responsable viaja en uno de los asientos, puede dejar
                    ese asiento en blanco: se usarán los datos del pagador. Para menores, la cédula puede ser
                    la del responsable.
                  </Alert>
                  {seleccionados.length === 0 && (
                    <Typography variant="body2" color="text.secondary">
                      Seleccione asientos en el mapa.
                    </Typography>
                  )}
                  {seleccionados.map((asientoId) => {
                    const p = pasajeros[asientoId] ?? {
                      nombre: '',
                      cedula: '',
                      esMenor: false,
                      edad: '',
                    };
                    return (
                      <Box
                        key={asientoId}
                        sx={{ mb: 2, p: 2, border: 1, borderColor: 'divider', borderRadius: 1 }}
                      >
                        <Typography variant="subtitle2" sx={{ mb: 1 }}>
                          <EventSeatIcon fontSize="small" sx={{ verticalAlign: 'middle', mr: 0.5 }} />
                          Asiento {numeroAsiento(asientoId)}
                        </Typography>
                        <TextField
                          required
                          fullWidth
                          size="small"
                          label="Nombre pasajero"
                          margin="dense"
                          value={p.nombre}
                          onChange={(e) => updatePasajero(asientoId, 'nombre', e.target.value)}
                        />
                        <TextField
                          fullWidth
                          size="small"
                          label="Cédula"
                          margin="dense"
                          value={p.cedula}
                          onChange={(e) => updatePasajero(asientoId, 'cedula', e.target.value)}
                          helperText={
                            !p.esMenor ? 'Opcional si es el mismo adulto responsable de abajo.' : undefined
                          }
                        />
                        <FormControlLabel
                          control={
                            <Checkbox
                              checked={p.esMenor}
                              onChange={(e) => updatePasajero(asientoId, 'esMenor', e.target.checked)}
                            />
                          }
                          label="Menor de 18 años"
                        />
                        {p.esMenor && (
                          <TextField
                            required
                            fullWidth
                            size="small"
                            type="number"
                            inputProps={{ min: 0, max: 17 }}
                            label="Edad"
                            margin="dense"
                            value={p.edad}
                            onChange={(e) => updatePasajero(asientoId, 'edad', e.target.value)}
                          />
                        )}
                      </Box>
                    );
                  })}
                  <Divider sx={{ my: 2 }} />
                  <Typography variant="subtitle2" gutterBottom>
                    Adulto responsable / pagador
                  </Typography>
                  <TextField
                    fullWidth
                    size="small"
                    label="Nombre responsable"
                    margin="dense"
                    value={compradorNombre}
                    onChange={(e) => setCompradorNombre(e.target.value)}
                  />
                  <TextField
                    fullWidth
                    size="small"
                    label="Cédula responsable"
                    margin="dense"
                    value={compradorCedula}
                    onChange={(e) => setCompradorCedula(e.target.value)}
                  />
                  <TextField
                    fullWidth
                    size="small"
                    label="Teléfono contacto"
                    margin="dense"
                    value={compradorTelefono}
                    onChange={(e) => setCompradorTelefono(e.target.value)}
                  />
                </Box>
              )}

              <TextField
                fullWidth
                type="number"
                inputProps={{ min: 0 }}
                label={`Equipaje extra (${formatearCordobas(tarifaEquipaje)}/u.)`}
                margin="dense"
                sx={{ mt: 1 }}
                value={equipajeExtra}
                onChange={(e) => setEquipajeExtra(Math.max(0, Number(e.target.value)))}
              />

              <Divider sx={{ my: 2 }} />
              <Typography variant="body2">
                Boletos ({seleccionados.length}): {formatearCordobas(subtotalBoletos)}
              </Typography>
              {subtotalEquipaje > 0 && (
                <Typography variant="body2">Equipaje: {formatearCordobas(subtotalEquipaje)}</Typography>
              )}
              <Typography sx={{ mt: 1, fontWeight: 600 }}>Total: {formatearCordobas(total)}</Typography>

              {seleccionados.length === 0 ? (
                <Button type="submit" variant="contained" fullWidth size="medium" sx={{ mt: 2 }} disabled>
                  Seleccione asientos primero
                </Button>
              ) : (
                <>
                  {!pasajerosValidos() && motivoFormularioInvalido() && (
                    <Alert severity="warning" sx={{ mt: 1, py: 0.25 }} icon={false}>
                      <Typography variant="caption">{motivoFormularioInvalido()}</Typography>
                    </Alert>
                  )}
                  <Button
                    type="submit"
                    variant="contained"
                    fullWidth
                    size="medium"
                    sx={{ mt: 1.5 }}
                    disabled={ventaLoading || !pasajerosValidos()}
                  >
                    {ventaLoading ? (
                      <CircularProgress size={22} color="inherit" />
                    ) : (
                      `Confirmar venta · ${formatearCordobas(total)}`
                    )}
                  </Button>
                </>
              )}
            </Box>
          </SectionCard>
        </Box>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mt: 2 }}>
          {error}
        </Alert>
      )}

      {ventaOk && (
        <Alert severity="success" sx={{ mt: 2 }}>
          Venta <strong>{ventaOk.codigo}</strong> registrada.{' '}
          <Button size="small" onClick={() => setMostrarComprobante(true)}>
            Ver comprobante
          </Button>
        </Alert>
      )}

      <ComprobanteVenta
        open={mostrarComprobante}
        venta={ventaOk}
        viajeInfo={
          detalle
            ? {
                origen: detalle.origen,
                destino: detalle.destino,
                fecha: detalle.fecha,
                hora: formatearHora(detalle.horaSalida),
                empresa: detalle.empresaNombre,
              }
            : undefined
        }
        onClose={() => setMostrarComprobante(false)}
      />

      {token && (
        <ReservaExcepcionalDialog
          open={dialogReserva}
          onClose={() => setDialogReserva(false)}
          token={token}
          detalle={detalle}
          onSuccess={() => recargarDetalle(detalle.viajeId)}
        />
      )}
    </Box>
  );
}
