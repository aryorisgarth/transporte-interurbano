import { useCallback, useEffect, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  FormControlLabel,
  Grid,
  IconButton,
  MenuItem,
  Switch,
  TextField,
  Typography,
} from '@mui/material';
import PersonAddIcon from '@mui/icons-material/PersonAdd';
import EditIcon from '@mui/icons-material/Edit';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import {
  actualizarOperador,
  crearOperador,
  listarOperadores,
  type UsuarioPerfil,
} from '@/shared/api';
import { CIUDADES_CORREDOR, type CiudadCorredor } from '@/shared/utils/corredor';

interface Props {
  token: string;
  empresaId: number;
}

const ETIQUETAS_ROL: Record<string, string> = {
  CAJERO: 'Cajero',
  ADMIN_EMPRESA: 'Admin empresa',
  RESERVA_EXCEPCIONAL: 'Reserva excepcional',
  ADMIN_GENERAL: 'Admin plataforma',
};

export function AdminOperadores({ token, empresaId }: Props) {
  const [operadores, setOperadores] = useState<UsuarioPerfil[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const [nombreUsuario, setNombreUsuario] = useState('');
  const [nombreCompleto, setNombreCompleto] = useState('');
  const [password, setPassword] = useState('password');
  const [email, setEmail] = useState('');
  const [esAdmin, setEsAdmin] = useState(false);
  const [reservaExcepcional, setReservaExcepcional] = useState(false);
  const [sedeCajero, setSedeCajero] = useState<CiudadCorredor>('Bluefields');

  const [editando, setEditando] = useState<UsuarioPerfil | null>(null);
  const [editNombre, setEditNombre] = useState('');
  const [editSede, setEditSede] = useState<CiudadCorredor>('Bluefields');
  const [editActivo, setEditActivo] = useState(true);
  const [editReserva, setEditReserva] = useState(false);
  const [editGuardando, setEditGuardando] = useState(false);
  const [eliminarOp, setEliminarOp] = useState<UsuarioPerfil | null>(null);

  const cargar = useCallback(async () => {
    setLoading(true);
    try {
      const data = await listarOperadores(token, empresaId);
      setOperadores(data);
    } catch (err) {
      setMsg({
        type: 'error',
        text: err instanceof Error ? err.message : 'Error al cargar operadores',
      });
    } finally {
      setLoading(false);
    }
  }, [token, empresaId]);

  useEffect(() => {
    cargar();
  }, [cargar]);

  async function handleCrear(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setMsg(null);

    const roles = [esAdmin ? 'ADMIN_EMPRESA' : 'CAJERO'];
    if (reservaExcepcional) roles.push('RESERVA_EXCEPCIONAL');

    try {
      await crearOperador(token, {
        empresaId,
        nombreUsuario: nombreUsuario.trim().toLowerCase(),
        nombreCompleto: nombreCompleto.trim(),
        password,
        roles,
        email: email.trim() || undefined,
        sede: esAdmin ? undefined : sedeCajero,
      });
      setMsg({ type: 'success', text: 'Operador creado. Ya puede iniciar sesión con Keycloak.' });
      setNombreUsuario('');
      setNombreCompleto('');
      setPassword('password');
      setEmail('');
      setEsAdmin(false);
      setReservaExcepcional(false);
      await cargar();
    } catch (err) {
      setMsg({
        type: 'error',
        text: err instanceof Error ? err.message : 'Error al crear operador',
      });
    } finally {
      setSaving(false);
    }
  }

  async function toggleActivo(op: UsuarioPerfil) {
    setMsg(null);
    try {
      await actualizarOperador(token, op.id, { activo: !op.activo });
      await cargar();
      setMsg({
        type: 'success',
        text: op.activo ? 'Operador desactivado' : 'Operador activado',
      });
    } catch (err) {
      setMsg({
        type: 'error',
        text: err instanceof Error ? err.message : 'Error al actualizar operador',
      });
    }
  }

  function abrirEditar(op: UsuarioPerfil) {
    setEditando(op);
    setEditNombre(op.nombreCompleto);
    setEditSede((op.sede as CiudadCorredor) ?? 'Bluefields');
    setEditActivo(op.activo ?? true);
    setEditReserva(op.roles.includes('RESERVA_EXCEPCIONAL'));
  }

  async function guardarEdicion(e: React.FormEvent) {
    e.preventDefault();
    if (!editando) return;
    setEditGuardando(true);
    setMsg(null);
    const esCajero = editando.roles.includes('CAJERO') && !editando.roles.includes('ADMIN_EMPRESA');
    try {
      await actualizarOperador(token, editando.id, {
        nombreCompleto: editNombre.trim(),
        activo: editActivo,
        sede: esCajero ? editSede : undefined,
        reservaExcepcional: editReserva,
      });
      setMsg({ type: 'success', text: 'Operador actualizado' });
      setEditando(null);
      await cargar();
    } catch (err) {
      setMsg({
        type: 'error',
        text: err instanceof Error ? err.message : 'Error al guardar cambios',
      });
    } finally {
      setEditGuardando(false);
    }
  }

  async function confirmarEliminarOperador() {
    if (!eliminarOp) return;
    setEditGuardando(true);
    setMsg(null);
    try {
      await actualizarOperador(token, eliminarOp.id, { activo: false });
      setMsg({ type: 'success', text: 'Operador eliminado (desactivado) — no puede iniciar sesión' });
      setEliminarOp(null);
      await cargar();
    } catch (err) {
      setMsg({
        type: 'error',
        text: err instanceof Error ? err.message : 'No se pudo eliminar',
      });
    } finally {
      setEditGuardando(false);
    }
  }

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" py={4}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
        Registre cajeros de su cooperativa indicando la <strong>terminal</strong> donde venden.
        Cada cajero solo ve viajes que salen desde su sede. Los administradores de empresa ven todas
        las terminales de su cooperativa.
      </Typography>

      {msg && (
        <Alert severity={msg.type} sx={{ mb: 2 }} onClose={() => setMsg(null)}>
          {msg.text}
        </Alert>
      )}

      <Grid container spacing={3}>
        <Grid item xs={12} md={5}>
          <Card component="form" onSubmit={handleCrear}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Nuevo operador
              </Typography>
              <TextField
                fullWidth
                required
                label="Usuario de login"
                margin="dense"
                placeholder="cajero2.wendelyn"
                value={nombreUsuario}
                onChange={(e) => setNombreUsuario(e.target.value)}
                helperText="Lo que escribe en Acceso personal — distinto del correo de contacto de la cooperativa"
              />
              <TextField
                fullWidth
                required
                label="Nombre completo"
                margin="dense"
                value={nombreCompleto}
                onChange={(e) => setNombreCompleto(e.target.value)}
              />
              <TextField
                fullWidth
                type="email"
                label="Email Keycloak (opcional)"
                margin="dense"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                helperText="Si vacío: usuario@transporte.local"
              />
              <TextField
                fullWidth
                required
                type="password"
                label="Contraseña inicial"
                margin="dense"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                helperText="Mínimo 6 caracteres"
              />
              <FormControlLabel
                sx={{ mt: 1, display: 'block' }}
                control={
                  <Switch checked={esAdmin} onChange={(e) => setEsAdmin(e.target.checked)} />
                }
                label="Es administrador de empresa (acceso a todas las terminales)"
              />
              {!esAdmin && (
                <TextField
                  fullWidth
                  select
                  required
                  label="Terminal del cajero"
                  margin="dense"
                  value={sedeCajero}
                  onChange={(e) => setSedeCajero(e.target.value as CiudadCorredor)}
                  helperText="Solo verá y venderá viajes que salen desde esta ciudad"
                >
                  {CIUDADES_CORREDOR.map((c) => (
                    <MenuItem key={c} value={c}>
                      {c}
                    </MenuItem>
                  ))}
                </TextField>
              )}
              <FormControlLabel
                control={
                  <Switch
                    checked={reservaExcepcional}
                    onChange={(e) => setReservaExcepcional(e.target.checked)}
                  />
                }
                label="Permiso reserva excepcional"
              />
              <Button
                type="submit"
                variant="contained"
                startIcon={saving ? <CircularProgress size={18} color="inherit" /> : <PersonAddIcon />}
                disabled={saving}
                sx={{ mt: 2 }}
              >
                Crear operador
              </Button>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={7}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Equipo ({operadores.length})
              </Typography>
              {operadores.length === 0 ? (
                <Alert severity="info">No hay operadores registrados para esta cooperativa.</Alert>
              ) : (
                operadores.map((op) => (
                  <Box
                    key={op.id}
                    sx={{
                      py: 1.5,
                      borderBottom: 1,
                      borderColor: 'divider',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'flex-start',
                      gap: 2,
                      flexWrap: 'wrap',
                    }}
                  >
                    <Box>
                      <Typography fontWeight={500}>{op.nombreCompleto}</Typography>
                      <Typography variant="body2" color="text.secondary">
                        Login: <strong>{op.nombreUsuario}</strong>
                        {op.emailLogin && op.emailLogin !== `${op.nombreUsuario}@transporte.local` && (
                          <> · Email Keycloak: {op.emailLogin}</>
                        )}
                        {op.sede ? ` · Terminal ${op.sede}` : op.roles.includes('ADMIN_EMPRESA') ? ' · Todas las terminales' : ''}
                      </Typography>
                      <Box sx={{ mt: 0.5, display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
                        {op.roles.map((r) => (
                          <Chip
                            key={r}
                            size="small"
                            label={ETIQUETAS_ROL[r] ?? r}
                            color={r === 'ADMIN_EMPRESA' ? 'secondary' : 'default'}
                          />
                        ))}
                        {!op.activo && <Chip size="small" label="Inactivo" color="warning" />}
                      </Box>
                    </Box>
                    <Box display="flex" alignItems="center" gap={1}>
                      <IconButton aria-label="Editar operador" onClick={() => abrirEditar(op)}>
                        <EditIcon />
                      </IconButton>
                      {op.activo && (
                        <IconButton
                          aria-label="Eliminar operador"
                          color="error"
                          onClick={() => setEliminarOp(op)}
                        >
                          <DeleteOutlineIcon />
                        </IconButton>
                      )}
                      <FormControlLabel
                      control={
                        <Switch
                          checked={op.activo}
                          onChange={() => toggleActivo(op)}
                          color="primary"
                        />
                      }
                      label={op.activo ? 'Activo' : 'Inactivo'}
                    />
                    </Box>
                  </Box>
                ))
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Dialog open={editando !== null} onClose={() => !editGuardando && setEditando(null)} maxWidth="sm" fullWidth>
        <Box component="form" onSubmit={guardarEdicion}>
          <DialogTitle>Editar operador</DialogTitle>
          <DialogContent>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              Usuario: <strong>{editando?.nombreUsuario}</strong> — el login no se cambia; cree otro usuario si
              necesita otro acceso.
            </Typography>
            <TextField
              fullWidth
              required
              label="Nombre completo"
              margin="dense"
              value={editNombre}
              onChange={(e) => setEditNombre(e.target.value)}
            />
            {editando &&
              editando.roles.includes('CAJERO') &&
              !editando.roles.includes('ADMIN_EMPRESA') && (
                <TextField
                  fullWidth
                  select
                  required
                  label="Terminal"
                  margin="dense"
                  value={editSede}
                  onChange={(e) => setEditSede(e.target.value as CiudadCorredor)}
                >
                  {CIUDADES_CORREDOR.map((c) => (
                    <MenuItem key={c} value={c}>
                      {c}
                    </MenuItem>
                  ))}
                </TextField>
              )}
            <FormControlLabel
              sx={{ mt: 1, display: 'block' }}
              control={<Switch checked={editActivo} onChange={(e) => setEditActivo(e.target.checked)} />}
              label="Cuenta activa"
            />
            <FormControlLabel
              control={<Switch checked={editReserva} onChange={(e) => setEditReserva(e.target.checked)} />}
              label="Permiso reserva excepcional"
            />
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setEditando(null)} disabled={editGuardando}>
              Cancelar
            </Button>
            <Button type="submit" variant="contained" disabled={editGuardando}>
              {editGuardando ? 'Guardando…' : 'Guardar'}
            </Button>
          </DialogActions>
        </Box>
      </Dialog>

      <Dialog open={eliminarOp !== null} onClose={() => !editGuardando && setEliminarOp(null)}>
        <DialogTitle>Eliminar operador</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Desactiva la cuenta de <strong>{eliminarOp?.nombreUsuario}</strong> (baja lógica). El historial de
            ventas se conserva. Puede reactivarlo desde editar.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEliminarOp(null)} disabled={editGuardando}>
            Cancelar
          </Button>
          <Button color="error" variant="contained" onClick={confirmarEliminarOperador} disabled={editGuardando}>
            {editGuardando ? 'Eliminando…' : 'Eliminar'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
