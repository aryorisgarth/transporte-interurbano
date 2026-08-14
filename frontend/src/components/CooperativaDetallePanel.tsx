import { useCallback, useEffect, useState } from 'react';
import {
  Alert,
  Avatar,
  Box,
  Button,
  Chip,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  Grid,
  IconButton,
  Stack,
  Tab,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Tabs,
  TextField,
  Tooltip,
  Typography,
} from '@mui/material';
import EditOutlinedIcon from '@mui/icons-material/EditOutlined';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import PersonAddOutlinedIcon from '@mui/icons-material/PersonAddOutlined';
import BlockOutlinedIcon from '@mui/icons-material/BlockOutlined';
import DirectionsBusOutlinedIcon from '@mui/icons-material/DirectionsBusOutlined';
import GroupsOutlinedIcon from '@mui/icons-material/GroupsOutlined';
import StorefrontOutlinedIcon from '@mui/icons-material/StorefrontOutlined';
import EmailOutlinedIcon from '@mui/icons-material/EmailOutlined';
import PhoneOutlinedIcon from '@mui/icons-material/PhoneOutlined';
import LuggageOutlinedIcon from '@mui/icons-material/LuggageOutlined';
import {
  actualizarOperador,
  crearOperador,
  detalleCooperativa,
  type DetalleCooperativa,
  type Empresa,
} from '../api/transporteApi';
import { PerfilEmpresaForm } from './PerfilEmpresaForm';
import { SectionCard } from './ui/SectionCard';

interface Props {
  token: string;
  empresaId: number;
  embedded?: boolean;
  onEmpresaActualizada?: (empresa: Empresa) => void;
  onRecargarLista?: () => void;
  onDesactivar?: () => void;
  canDesactivar?: boolean;
  onAsignarAdmin?: () => void;
  sinAdmin?: boolean;
}

const ETIQUETAS_ROL: Record<string, string> = {
  CAJERO: 'Cajero',
  ADMIN_EMPRESA: 'Admin empresa',
  RESERVA_EXCEPCIONAL: 'Reserva excepcional',
};

const AVATAR_PALETTE = ['#0f766e', '#0c4a6e', '#7c3aed', '#0369a1', '#c2410c', '#be123c'];

function iniciales(nombre: string): string {
  const partes = nombre.trim().split(/\s+/).filter(Boolean);
  if (partes.length === 0) return '?';
  if (partes.length === 1) return partes[0].slice(0, 2).toUpperCase();
  return (partes[0][0] + partes[1][0]).toUpperCase();
}

function esAdminEmpresa(roles: string[]) {
  return roles.includes('ADMIN_EMPRESA');
}

function esCajeroPuro(roles: string[]) {
  return roles.includes('CAJERO') && !roles.includes('ADMIN_EMPRESA');
}

function MetricBadge({ label, value }: { label: string; value: number }) {
  return (
    <Box className="platform-metric-badge">
      <Typography variant="h6" fontWeight={800} lineHeight={1}>
        {value}
      </Typography>
      <Typography variant="caption" color="text.secondary" fontWeight={600}>
        {label}
      </Typography>
    </Box>
  );
}

export function CooperativaDetallePanel({
  token,
  empresaId,
  embedded = false,
  onEmpresaActualizada,
  onRecargarLista,
  onDesactivar,
  canDesactivar = true,
  onAsignarAdmin,
  sinAdmin = false,
}: Props) {
  const [tab, setTab] = useState(0);
  const [detalle, setDetalle] = useState<DetalleCooperativa | null>(null);
  const [loading, setLoading] = useState(true);
  const [msg, setMsg] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const [adminUsuario, setAdminUsuario] = useState('');
  const [adminNombre, setAdminNombre] = useState('');
  const [adminEmail, setAdminEmail] = useState('');
  const [adminPassword, setAdminPassword] = useState('password');
  const [creandoAdmin, setCreandoAdmin] = useState(false);

  const [editando, setEditando] = useState<DetalleCooperativa['operadores'][0] | null>(null);
  const [editNombre, setEditNombre] = useState('');
  const [editActivo, setEditActivo] = useState(true);
  const [editGuardando, setEditGuardando] = useState(false);
  const [eliminarOp, setEliminarOp] = useState<DetalleCooperativa['operadores'][0] | null>(null);

  const cargar = useCallback(async () => {
    setLoading(true);
    try {
      setDetalle(await detalleCooperativa(token, empresaId));
    } catch (err) {
      setMsg({ type: 'error', text: err instanceof Error ? err.message : 'Error al cargar detalle' });
      setDetalle(null);
    } finally {
      setLoading(false);
    }
  }, [token, empresaId]);

  useEffect(() => {
    cargar();
  }, [cargar]);

  async function handleCrearAdmin(e: React.FormEvent) {
    e.preventDefault();
    setCreandoAdmin(true);
    setMsg(null);
    try {
      await crearOperador(token, {
        empresaId,
        nombreUsuario: adminUsuario.trim().toLowerCase(),
        nombreCompleto: adminNombre.trim(),
        password: adminPassword,
        roles: ['ADMIN_EMPRESA'],
        email: adminEmail.trim() || undefined,
      });
      setMsg({ type: 'success', text: `Administrador «${adminUsuario}» creado correctamente.` });
      setAdminUsuario('');
      setAdminNombre('');
      setAdminEmail('');
      setAdminPassword('password');
      await cargar();
      onRecargarLista?.();
    } catch (err) {
      setMsg({ type: 'error', text: err instanceof Error ? err.message : 'No se pudo crear el administrador' });
    } finally {
      setCreandoAdmin(false);
    }
  }

  function abrirEditar(op: DetalleCooperativa['operadores'][0]) {
    if (!esAdminEmpresa(op.roles)) return;
    setEditando(op);
    setEditNombre(op.nombreCompleto);
    setEditActivo(op.activo);
  }

  async function guardarEdicion(e: React.FormEvent) {
    e.preventDefault();
    if (!editando) return;
    setEditGuardando(true);
    try {
      await actualizarOperador(token, editando.id, {
        nombreCompleto: editNombre.trim(),
        activo: editActivo,
      });
      setEditando(null);
      setMsg({ type: 'success', text: 'Administrador actualizado' });
      await cargar();
      onRecargarLista?.();
    } catch (err) {
      setMsg({ type: 'error', text: err instanceof Error ? err.message : 'Error al guardar' });
    } finally {
      setEditGuardando(false);
    }
  }

  async function confirmarEliminar() {
    if (!eliminarOp) return;
    setEditGuardando(true);
    try {
      await actualizarOperador(token, eliminarOp.id, { activo: false });
      setEliminarOp(null);
      setMsg({ type: 'success', text: 'Administrador desactivado' });
      await cargar();
      onRecargarLista?.();
    } catch (err) {
      setMsg({ type: 'error', text: err instanceof Error ? err.message : 'No se pudo desactivar' });
    } finally {
      setEditGuardando(false);
    }
  }

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight={200}>
        <CircularProgress size={28} />
      </Box>
    );
  }

  if (!detalle) {
    return <Alert severity="error">{msg?.text ?? 'No se pudo cargar la cooperativa'}</Alert>;
  }

  const { empresa, metricas, operadores, buses } = detalle;
  const cajeros = operadores.filter((o) => esCajeroPuro(o.roles));
  const avatarBg = AVATAR_PALETTE[empresa.id % AVATAR_PALETTE.length];

  const header = (
    <Box className="platform-coop-detail-header">
      <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems={{ sm: 'center' }} justifyContent="space-between">
        <Stack direction="row" spacing={2} alignItems="center" sx={{ minWidth: 0 }}>
          <Avatar sx={{ width: 52, height: 52, fontWeight: 700, bgcolor: avatarBg, fontSize: '1rem' }}>
            {iniciales(empresa.nombre)}
          </Avatar>
          <Box sx={{ minWidth: 0 }}>
            <Stack direction="row" alignItems="center" spacing={1} flexWrap="wrap" useFlexGap>
              <Typography variant="h6" fontWeight={800} noWrap>
                {empresa.nombre}
              </Typography>
              {sinAdmin ? (
                <Chip size="small" label="Sin administrador" color="warning" variant="outlined" />
              ) : (
                <Chip size="small" label="Activa" color="success" variant="outlined" />
              )}
            </Stack>
            <Stack direction="row" spacing={2} flexWrap="wrap" useFlexGap sx={{ mt: 0.5 }}>
              {empresa.correo && (
                <Stack direction="row" spacing={0.5} alignItems="center">
                  <EmailOutlinedIcon sx={{ fontSize: 14, color: 'text.secondary' }} />
                  <Typography variant="caption" color="text.secondary">
                    {empresa.correo}
                  </Typography>
                </Stack>
              )}
              {empresa.telefono && (
                <Stack direction="row" spacing={0.5} alignItems="center">
                  <PhoneOutlinedIcon sx={{ fontSize: 14, color: 'text.secondary' }} />
                  <Typography variant="caption" color="text.secondary">
                    {empresa.telefono}
                  </Typography>
                </Stack>
              )}
              <Stack direction="row" spacing={0.5} alignItems="center">
                <LuggageOutlinedIcon sx={{ fontSize: 14, color: 'text.secondary' }} />
                <Typography variant="caption" color="text.secondary">
                  Equipaje C$ {Number(empresa.tarifaEquipajeExtra)}
                </Typography>
              </Stack>
            </Stack>
          </Box>
        </Stack>

        <Stack direction="row" spacing={1} flexShrink={0}>
          {sinAdmin && onAsignarAdmin && (
            <Button size="small" variant="contained" color="warning" startIcon={<PersonAddOutlinedIcon />} onClick={onAsignarAdmin}>
              Asignar admin
            </Button>
          )}
          {onDesactivar && (
            <Tooltip title={!canDesactivar ? 'Debe permanecer al menos una cooperativa activa' : ''}>
              <span>
                <Button
                  size="small"
                  variant="outlined"
                  color="inherit"
                  startIcon={<BlockOutlinedIcon />}
                  onClick={onDesactivar}
                  disabled={!canDesactivar}
                  sx={{ borderColor: 'divider' }}
                >
                  Desactivar
                </Button>
              </span>
            </Tooltip>
          )}
        </Stack>
      </Stack>

      <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap className="platform-coop-detail-metrics" sx={{ mt: 2 }}>
        <MetricBadge label="Buses" value={metricas.busesActivos} />
        <MetricBadge label="Admins" value={metricas.adminsActivos} />
        <MetricBadge label="Cajeros" value={metricas.cajerosActivos} />
        <MetricBadge label="Viajes hoy" value={metricas.viajesHoy} />
        <MetricBadge label="Boletos hoy" value={metricas.boletosVendidosHoy} />
      </Stack>
    </Box>
  );

  const body = (
    <Box className="platform-coop-detail-body">
      {msg && (
        <Alert severity={msg.type} sx={{ mb: 2 }} onClose={() => setMsg(null)}>
          {msg.text}
        </Alert>
      )}

      <Tabs
        value={tab}
        onChange={(_, v) => setTab(v)}
        className="dashboard-tabs platform-coop-tabs-pro"
        sx={{ mb: 2 }}
      >
        <Tab label="Accesos" icon={<GroupsOutlinedIcon />} iconPosition="start" />
        <Tab label="Datos comerciales" icon={<StorefrontOutlinedIcon />} iconPosition="start" />
        <Tab label={`Flota (${buses.length})`} icon={<DirectionsBusOutlinedIcon />} iconPosition="start" />
      </Tabs>

      {tab === 0 && (
        <Grid container spacing={2.5}>
          <Grid item xs={12} lg={4}>
            <Box className="platform-form-panel">
              <Typography variant="subtitle2" fontWeight={700} gutterBottom>
                Nuevo administrador
              </Typography>
              <Typography variant="caption" color="text.secondary" display="block" sx={{ mb: 2 }}>
                Crea cuentas ADMIN_EMPRESA. Los cajeros los gestiona el admin de la cooperativa.
              </Typography>
              <Box component="form" onSubmit={handleCrearAdmin}>
                <TextField fullWidth required size="small" label="Usuario de login" margin="dense" value={adminUsuario} onChange={(e) => setAdminUsuario(e.target.value)} />
                <TextField fullWidth required size="small" label="Nombre completo" margin="dense" value={adminNombre} onChange={(e) => setAdminNombre(e.target.value)} />
                <TextField fullWidth size="small" type="email" label="Email Keycloak" margin="dense" value={adminEmail} onChange={(e) => setAdminEmail(e.target.value)} />
                <TextField fullWidth required size="small" type="password" label="Contraseña inicial" margin="dense" value={adminPassword} onChange={(e) => setAdminPassword(e.target.value)} />
                <Button
                  type="submit"
                  variant="contained"
                  fullWidth
                  startIcon={creandoAdmin ? <CircularProgress size={18} color="inherit" /> : <PersonAddOutlinedIcon />}
                  disabled={creandoAdmin}
                  sx={{ mt: 2 }}
                >
                  Crear administrador
                </Button>
              </Box>
            </Box>
          </Grid>

          <Grid item xs={12} lg={8}>
            <TableContainer className="admin-data-table">
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Nombre</TableCell>
                    <TableCell>Usuario login</TableCell>
                    <TableCell>Email Keycloak</TableCell>
                    <TableCell>Rol / Terminal</TableCell>
                    <TableCell align="right">Acciones</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {operadores.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} align="center" sx={{ py: 4, color: 'text.secondary' }}>
                        Sin operadores registrados
                      </TableCell>
                    </TableRow>
                  ) : (
                    operadores.map((op) => (
                      <TableRow key={op.id} hover sx={{ opacity: op.activo ? 1 : 0.6 }}>
                        <TableCell>{op.nombreCompleto}</TableCell>
                        <TableCell>
                          <Typography component="span" variant="body2" fontFamily="monospace" fontWeight={600}>
                            {op.nombreUsuario}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" color="text.secondary" sx={{ wordBreak: 'break-all' }}>
                            {op.emailLogin}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Stack direction="row" spacing={0.5} flexWrap="wrap" useFlexGap>
                            {op.roles.map((r) => (
                              <Chip key={r} size="small" label={ETIQUETAS_ROL[r] ?? r} />
                            ))}
                            {op.sede && <Chip size="small" label={op.sede} variant="outlined" />}
                            {!op.activo && <Chip size="small" label="Inactivo" color="warning" />}
                          </Stack>
                        </TableCell>
                        <TableCell align="right">
                          {esAdminEmpresa(op.roles) ? (
                            <>
                              <IconButton size="small" onClick={() => abrirEditar(op)} aria-label="Editar">
                                <EditOutlinedIcon fontSize="small" />
                              </IconButton>
                              {op.activo && (
                                <IconButton size="small" color="error" onClick={() => setEliminarOp(op)} aria-label="Desactivar">
                                  <DeleteOutlineIcon fontSize="small" />
                                </IconButton>
                              )}
                            </>
                          ) : (
                            <Typography variant="caption" color="text.secondary">
                              Solo lectura
                            </Typography>
                          )}
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </TableContainer>
            {cajeros.length > 0 && (
              <Typography variant="caption" color="text.secondary" display="block" sx={{ mt: 1 }}>
                {cajeros.length} cajero(s) gestionados por el admin de empresa.
              </Typography>
            )}
          </Grid>
        </Grid>
      )}

      {tab === 1 && (
        <PerfilEmpresaForm
          token={token}
          empresaId={empresaId}
          esGlobal
          onActualizado={(e) => {
            onEmpresaActualizada?.(e);
            cargar();
          }}
        />
      )}

      {tab === 2 && (
        <TableContainer className="admin-data-table">
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Número</TableCell>
                <TableCell>Placa</TableCell>
                <TableCell>Terminal base</TableCell>
                <TableCell align="right">Capacidad</TableCell>
                <TableCell>Estado</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {buses.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} align="center" sx={{ py: 4, color: 'text.secondary' }}>
                    Sin buses registrados
                  </TableCell>
                </TableRow>
              ) : (
                buses.map((b) => (
                  <TableRow key={b.id} hover>
                    <TableCell>{b.numeroInterno}</TableCell>
                    <TableCell>{b.placa}</TableCell>
                    <TableCell>{b.sede}</TableCell>
                    <TableCell align="right">{b.capacidad}</TableCell>
                    <TableCell>
                      <Chip size="small" label={b.activo ? 'Activo' : 'Inactivo'} color={b.activo ? 'success' : 'default'} />
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>
      )}
    </Box>
  );

  const dialogs = (
    <>
      <Dialog open={editando !== null} onClose={() => !editGuardando && setEditando(null)} maxWidth="sm" fullWidth>
        <Box component="form" onSubmit={guardarEdicion}>
          <DialogTitle>Editar administrador</DialogTitle>
          <DialogContent>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              Login: <strong>{editando?.nombreUsuario}</strong>
            </Typography>
            <TextField fullWidth required label="Nombre completo" margin="dense" value={editNombre} onChange={(e) => setEditNombre(e.target.value)} />
            <Stack direction="row" alignItems="center" spacing={1} sx={{ mt: 2 }}>
              <Chip label={editActivo ? 'Activo' : 'Inactivo'} color={editActivo ? 'success' : 'warning'} onClick={() => setEditActivo((v) => !v)} />
              <Typography variant="caption" color="text.secondary">
                Clic para cambiar estado
              </Typography>
            </Stack>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setEditando(null)} disabled={editGuardando}>
              Cancelar
            </Button>
            <Button type="submit" variant="contained" disabled={editGuardando}>
              Guardar
            </Button>
          </DialogActions>
        </Box>
      </Dialog>

      <Dialog open={eliminarOp !== null} onClose={() => !editGuardando && setEliminarOp(null)}>
        <DialogTitle>Desactivar administrador</DialogTitle>
        <DialogContent>
          <DialogContentText>
            ¿Desactivar <strong>{eliminarOp?.nombreUsuario}</strong>? No podrá iniciar sesión.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEliminarOp(null)} disabled={editGuardando}>
            Cancelar
          </Button>
          <Button color="error" variant="contained" onClick={confirmarEliminar} disabled={editGuardando}>
            Desactivar
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );

  if (embedded) {
    return (
      <Box className="platform-coop-detail platform-coop-detail--embedded">
        {header}
        {body}
        {dialogs}
      </Box>
    );
  }

  return (
    <Box className="platform-coop-detail">
      <SectionCard noPadding>
        {header}
        {body}
      </SectionCard>
      {dialogs}
    </Box>
  );
}
 