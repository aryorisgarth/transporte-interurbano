import { useState } from 'react';
import {
  Alert,
  Box,
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  MenuItem,
  TextField,
} from '@mui/material';
import { crearReservaExcepcional, type DetalleViaje } from '@/shared/api';

interface Props {
  open: boolean;
  onClose: () => void;
  token: string;
  detalle: DetalleViaje;
  onSuccess: () => void;
}

export function ReservaExcepcionalDialog({ open, onClose, token, detalle, onSuccess }: Props) {
  const [asientoId, setAsientoId] = useState<number | ''>('');
  const [nombre, setNombre] = useState('');
  const [cedula, setCedula] = useState('');
  const [telefono, setTelefono] = useState('');
  const [motivo, setMotivo] = useState('');
  const [horas, setHoras] = useState(24);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const disponibles = detalle.asientos.filter((a) => a.estado === 'DISPONIBLE');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (asientoId === '') return;
    setLoading(true);
    setError(null);
    try {
      await crearReservaExcepcional(token, {
        viajeAsientoId: asientoId as number,
        compradorNombre: nombre,
        compradorCedula: cedula,
        compradorTelefono: telefono || undefined,
        motivo,
        horasExpiracion: horas,
      });
      onSuccess();
      onClose();
      setAsientoId('');
      setNombre('');
      setCedula('');
      setTelefono('');
      setMotivo('');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al reservar');
    } finally {
      setLoading(false);
    }
  }

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <form onSubmit={handleSubmit}>
        <DialogTitle>Reserva excepcional</DialogTitle>
        <DialogContent>
          <Alert severity="warning" sx={{ mb: 2 }}>
            Casos autorizados (gobierno, empleados). No genera venta; el asiento queda apartado sin
            pago.
          </Alert>
          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}
          <TextField
            select
            fullWidth
            required
            label="Asiento disponible"
            margin="dense"
            value={asientoId}
            onChange={(e) => setAsientoId(Number(e.target.value))}
          >
            {disponibles.map((a) => (
              <MenuItem key={a.viajeAsientoId} value={a.viajeAsientoId}>
                Asiento {a.numero} ({a.posicion})
              </MenuItem>
            ))}
          </TextField>
          <TextField
            fullWidth
            required
            label="Nombre"
            margin="dense"
            value={nombre}
            onChange={(e) => setNombre(e.target.value)}
          />
          <TextField
            fullWidth
            required
            label="Cédula"
            margin="dense"
            value={cedula}
            onChange={(e) => setCedula(e.target.value)}
          />
          <TextField
            fullWidth
            label="Teléfono"
            margin="dense"
            value={telefono}
            onChange={(e) => setTelefono(e.target.value)}
          />
          <TextField
            fullWidth
            required
            multiline
            minRows={2}
            label="Motivo (obligatorio)"
            margin="dense"
            value={motivo}
            onChange={(e) => setMotivo(e.target.value)}
          />
          <TextField
            fullWidth
            type="number"
            inputProps={{ min: 1, max: 72 }}
            label="Expira en (horas)"
            margin="dense"
            value={horas}
            onChange={(e) => setHoras(Number(e.target.value))}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={onClose}>Cancelar</Button>
          <Button type="submit" variant="contained" disabled={loading || disponibles.length === 0}>
            {loading ? <CircularProgress size={22} /> : 'Apartar asiento'}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
}
