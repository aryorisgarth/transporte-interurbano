import { useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  IconButton,
  TextField,
  Typography,
} from '@mui/material';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import EditIcon from '@mui/icons-material/Edit';
import { actualizarViaje, cancelarViaje, type ViajeOperador } from '@/shared/api';
import { formatearCordobas, formatearHora, componerHoraBackend, descomponerHora24, HORA_SALIDA_DEFAULT, type HoraSalidaNicaragua, ETIQUETAS_ESTADO_VIAJE } from '@/shared/utils/formato';
import { HoraSalidaField } from '@/shared/ui/HoraSalidaField';

interface Props {
  token: string;
  viajes: ViajeOperador[];
  onActualizado: () => void;
  onMsg: (msg: { type: 'success' | 'error'; text: string } | null) => void;
}

export function AdminViajesLista({ token, viajes, onActualizado, onMsg }: Props) {
  const [editando, setEditando] = useState<ViajeOperador | null>(null);
  const [cancelarId, setCancelarId] = useState<number | null>(null);
  const [hora, setHora] = useState<HoraSalidaNicaragua>(HORA_SALIDA_DEFAULT);
  const [tarifa, setTarifa] = useState(350);
  const [observaciones, setObservaciones] = useState('');
  const [guardando, setGuardando] = useState(false);

  function abrirEditar(v: ViajeOperador) {
    setEditando(v);
    setHora(descomponerHora24(String(v.horaSalida)));
    setTarifa(Number(v.tarifa));
    setObservaciones('');
  }

  async function guardar(e: React.FormEvent) {
    e.preventDefault();
    if (!editando) return;
    if (tarifa < 0) {
      onMsg({ type: 'error', text: 'La tarifa no puede ser negativa (RN V2).' });
      return;
    }
    setGuardando(true);
    onMsg(null);
    try {
      await actualizarViaje(token, editando.id, {
        horaSalida: componerHoraBackend(hora),
        tarifa,
        observaciones: observaciones.trim() || undefined,
      });
      onMsg({ type: 'success', text: 'Viaje actualizado' });
      setEditando(null);
      onActualizado();
    } catch (err) {
      onMsg({ type: 'error', text: err instanceof Error ? err.message : 'Error al actualizar viaje' });
    } finally {
      setGuardando(false);
    }
  }

  async function confirmarCancelar() {
    if (cancelarId === null) return;
    setGuardando(true);
    onMsg(null);
    try {
      await cancelarViaje(token, cancelarId);
      onMsg({ type: 'success', text: 'Viaje cancelado (RN V5 — no permite nuevas ventas)' });
      setCancelarId(null);
      onActualizado();
    } catch (err) {
      onMsg({ type: 'error', text: err instanceof Error ? err.message : 'No se pudo cancelar' });
    } finally {
      setGuardando(false);
    }
  }

  if (viajes.length === 0) {
    return <Alert severity="info">No hay viajes programados para esta fecha.</Alert>;
  }

  return (
    <>
      {viajes.map((v) => {
        const programado = v.estado === 'PROGRAMADO';
        return (
          <Box
            key={v.id}
            sx={{
              py: 1,
              borderBottom: 1,
              borderColor: 'divider',
              display: 'flex',
              gap: 1,
              alignItems: 'flex-start',
              opacity: v.estado === 'CANCELADO' ? 0.6 : 1,
            }}
          >
            <Box flex={1}>
              <Typography>
                {v.origen} → {v.destino} · {formatearHora(String(v.horaSalida))} ·{' '}
                {formatearCordobas(Number(v.tarifa))}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Bus {v.busNumeroInterno} · {v.asientosDisponibles} cupos ·{' '}
                {ETIQUETAS_ESTADO_VIAJE[v.estado] ?? v.estado}
              </Typography>
              <Box sx={{ mt: 0.5, display: 'flex', gap: 0.5 }}>
                {v.estado === 'CANCELADO' && <Chip size="small" label="Cancelado" color="warning" />}
                {!programado && v.estado !== 'CANCELADO' && (
                  <Chip size="small" label={ETIQUETAS_ESTADO_VIAJE[v.estado] ?? v.estado} />
                )}
              </Box>
            </Box>
            {programado && (
              <>
                <IconButton aria-label="Editar viaje" onClick={() => abrirEditar(v)}>
                  <EditIcon />
                </IconButton>
                <IconButton aria-label="Eliminar viaje" color="error" onClick={() => setCancelarId(v.id)}>
                  <DeleteOutlineIcon />
                </IconButton>
              </>
            )}
          </Box>
        );
      })}

      <Dialog open={editando !== null} onClose={() => !guardando && setEditando(null)} maxWidth="sm" fullWidth>
        <Box component="form" onSubmit={guardar}>
          <DialogTitle>
            Editar viaje {editando?.origen} → {editando?.destino}
          </DialogTitle>
          <DialogContent>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              Origen, destino, fecha y bus no se cambian (evita inconsistencias). Si hay ventas, la hora tampoco.
            </Typography>
            <HoraSalidaField value={hora} onChange={setHora} />
            <TextField
              fullWidth
              type="number"
              inputProps={{ min: 0 }}
              label="Tarifa C$"
              margin="dense"
              value={tarifa}
              onChange={(e) => setTarifa(Number(e.target.value))}
            />
            <TextField
              fullWidth
              label="Observaciones"
              margin="dense"
              multiline
              minRows={2}
              value={observaciones}
              onChange={(e) => setObservaciones(e.target.value)}
            />
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setEditando(null)} disabled={guardando}>
              Cerrar
            </Button>
            <Button type="submit" variant="contained" disabled={guardando}>
              {guardando ? 'Guardando…' : 'Guardar'}
            </Button>
          </DialogActions>
        </Box>
      </Dialog>

      <Dialog open={cancelarId !== null} onClose={() => !guardando && setCancelarId(null)}>
        <DialogTitle>Eliminar viaje</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Cancela el viaje (baja lógica). No se borra el registro. Solo si no hay boletos vendidos o
            reservas activas.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCancelarId(null)} disabled={guardando}>
            No
          </Button>
          <Button color="error" variant="contained" onClick={confirmarCancelar} disabled={guardando}>
            {guardando ? 'Eliminando…' : 'Eliminar viaje'}
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
}
