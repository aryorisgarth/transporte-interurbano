import { useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControlLabel,
  IconButton,
  MenuItem,
  Switch,
  TextField,
  Typography,
} from '@mui/material';
import EditIcon from '@mui/icons-material/Edit';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import type { Bus } from '@/shared/api';
import { actualizarBus } from '@/shared/api';
import { CIUDADES_CORREDOR, type CiudadCorredor } from '@/shared/utils/corredor';

interface Props {
  token: string;
  buses: Bus[];
  onActualizado: () => void;
  onMsg: (msg: { type: 'success' | 'error'; text: string } | null) => void;
}

export function AdminFlotaLista({ token, buses, onActualizado, onMsg }: Props) {
  const [editando, setEditando] = useState<Bus | null>(null);
  const [numeroInterno, setNumeroInterno] = useState('');
  const [placa, setPlaca] = useState('');
  const [sede, setSede] = useState<CiudadCorredor>('Bluefields');
  const [fotoUrl, setFotoUrl] = useState('');
  const [activo, setActivo] = useState(true);
  const [guardando, setGuardando] = useState(false);
  const [eliminarId, setEliminarId] = useState<number | null>(null);

  function abrirEditar(bus: Bus) {
    setEditando(bus);
    setNumeroInterno(bus.numeroInterno);
    setPlaca(bus.placa);
    setSede(bus.sede as CiudadCorredor);
    setFotoUrl(bus.fotoUrl ?? '');
    setActivo(bus.activo);
  }

  async function guardar(e: React.FormEvent) {
    e.preventDefault();
    if (!editando) return;
    setGuardando(true);
    onMsg(null);
    try {
      await actualizarBus(token, editando.id, {
        numeroInterno: numeroInterno.trim(),
        placa: placa.trim(),
        sede,
        fotoUrl: fotoUrl.trim() || undefined,
        activo,
      });
      onMsg({ type: 'success', text: activo ? 'Bus actualizado' : 'Bus desactivado (no aparece en nuevos viajes)' });
      setEditando(null);
      onActualizado();
    } catch (err) {
      onMsg({ type: 'error', text: err instanceof Error ? err.message : 'Error al actualizar bus' });
    } finally {
      setGuardando(false);
    }
  }

  async function confirmarEliminar() {
    const bus = buses.find((b) => b.id === eliminarId);
    if (!bus) return;
    setGuardando(true);
    onMsg(null);
    try {
      await actualizarBus(token, bus.id, {
        numeroInterno: bus.numeroInterno,
        placa: bus.placa,
        sede: bus.sede,
        fotoUrl: bus.fotoUrl ?? undefined,
        activo: false,
      });
      onMsg({ type: 'success', text: 'Bus eliminado (desactivado) — no se usa en nuevos viajes' });
      setEliminarId(null);
      onActualizado();
    } catch (err) {
      onMsg({ type: 'error', text: err instanceof Error ? err.message : 'No se pudo eliminar' });
    } finally {
      setGuardando(false);
    }
  }

  if (buses.length === 0) {
    return <Alert severity="info">No hay buses registrados. Agregue uno con el formulario.</Alert>;
  }

  return (
    <>
      {buses.map((b) => (
        <Box
          key={b.id}
          sx={{
            py: 1,
            borderBottom: 1,
            borderColor: 'divider',
            display: 'flex',
            gap: 2,
            alignItems: 'center',
            opacity: b.activo ? 1 : 0.65,
          }}
        >
          {b.fotoUrl && (
            <Box
              component="img"
              src={b.fotoUrl}
              alt={b.numeroInterno}
              sx={{ width: 56, height: 40, objectFit: 'cover', borderRadius: 1 }}
            />
          )}
          <Box flex={1}>
            <Typography>
              {b.numeroInterno} · {b.placa} · {b.capacidad} asientos · <strong>Sede {b.sede}</strong>
            </Typography>
            {!b.activo && (
              <Chip size="small" label="Inactivo" color="warning" sx={{ mt: 0.5 }} />
            )}
          </Box>
          <IconButton aria-label="Editar bus" onClick={() => abrirEditar(b)}>
            <EditIcon />
          </IconButton>
          {b.activo && (
            <IconButton aria-label="Eliminar bus" color="error" onClick={() => setEliminarId(b.id)}>
              <DeleteOutlineIcon />
            </IconButton>
          )}
        </Box>
      ))}

      <Dialog open={editando !== null} onClose={() => !guardando && setEditando(null)} maxWidth="sm" fullWidth>
        <Box component="form" onSubmit={guardar}>
          <DialogTitle>Editar bus {editando?.numeroInterno}</DialogTitle>
          <DialogContent>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              La capacidad no se modifica (layout de asientos ya generado). Desactive el bus si sale de servicio.
            </Typography>
            <TextField
              fullWidth
              required
              label="Número interno"
              margin="dense"
              value={numeroInterno}
              onChange={(e) => setNumeroInterno(e.target.value)}
            />
            <TextField
              fullWidth
              required
              label="Placa"
              margin="dense"
              value={placa}
              onChange={(e) => setPlaca(e.target.value)}
              helperText="Placa única en el sistema (RN BU3)"
            />
            <TextField
              fullWidth
              select
              required
              label="Terminal base (sede)"
              margin="dense"
              value={sede}
              onChange={(e) => setSede(e.target.value as CiudadCorredor)}
            >
              {CIUDADES_CORREDOR.map((c) => (
                <MenuItem key={c} value={c}>
                  {c}
                </MenuItem>
              ))}
            </TextField>
            <TextField
              fullWidth
              label="URL foto"
              margin="dense"
              value={fotoUrl}
              onChange={(e) => setFotoUrl(e.target.value)}
            />
            <FormControlLabel
              sx={{ mt: 1 }}
              control={<Switch checked={activo} onChange={(e) => setActivo(e.target.checked)} />}
              label={activo ? 'Bus activo en flota' : 'Bus inactivo'}
            />
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setEditando(null)} disabled={guardando}>
              Cancelar
            </Button>
            <Button type="submit" variant="contained" disabled={guardando}>
              {guardando ? 'Guardando…' : 'Guardar'}
            </Button>
          </DialogActions>
        </Box>
      </Dialog>

      <Dialog open={eliminarId !== null} onClose={() => !guardando && setEliminarId(null)}>
        <DialogTitle>Eliminar bus</DialogTitle>
        <DialogContent>
          <Typography variant="body2">
            Baja lógica: el bus queda inactivo (no se borra de la base de datos por historial de viajes).
            Puede reactivarlo desde editar.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEliminarId(null)} disabled={guardando}>
            Cancelar
          </Button>
          <Button color="error" variant="contained" onClick={confirmarEliminar} disabled={guardando}>
            {guardando ? 'Eliminando…' : 'Eliminar'}
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
}
