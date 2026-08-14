import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Avatar,
  Box,
  Button,
  Card,
  Chip,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  Divider,
  Grid,
  InputAdornment,
  Stack,
  Step,
  StepLabel,
  Stepper,
  TextField,
  Typography,
} from '@mui/material';
import AddBusinessIcon from '@mui/icons-material/AddBusiness';
import BusinessIcon from '@mui/icons-material/Business';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import ConfirmationNumberIcon from '@mui/icons-material/ConfirmationNumber';
import DirectionsBusIcon from '@mui/icons-material/DirectionsBus';
import EventNoteIcon from '@mui/icons-material/EventNote';
import SearchIcon from '@mui/icons-material/Search';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import {
  crearEmpresa,
  crearOperador,
  desactivarEmpresa,
  listarEmpresas,
  resumenPlataforma,
  type Empresa,
  type ResumenEmpresa,
} from '@/shared/api';
import { CooperativaDetallePanel } from '@/features/admin/components/CooperativaDetallePanel';
import { StatCard } from '@/shared/ui/StatCard';

interface Props {
  token: string;
  empresas: Empresa[];
  empresaIdSeleccionada: number | '';
  onEmpresasActualizadas: (list: Empresa[], seleccionarId?: number) => void;
  onSeleccionarEmpresa: (id: number) => void;
}

const PASOS = ['Datos de la cooperativa', 'Administrador inicial'];

function correoValido(correo: string): boolean {
  if (!correo.trim()) return true;
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo.trim());
}

function sugerirUsuarioAdmin(nombreCoop: string): string {
  const slug = nombreCoop
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '.')
    .replace(/^\.+|\.+$/g, '')
    .slice(0, 24);
  return slug ? `admin.${slug}` : 'admin.nueva.coop';
}

function iniciales(nombre: string): string {
  const partes = nombre.trim().split(/\s+/).filter(Boolean);
  if (partes.length === 0) return '?';
  if (partes.length === 1) return partes[0].slice(0, 2).toUpperCase();
  return (partes[0][0] + partes[1][0]).toUpperCase();
}

function avatarColor(id: number): string {
  const palette = ['#0f766e', '#0c4a6e', '#7c3aed', '#0369a1', '#c2410c', '#be123c'];
  return palette[id % palette.length];
}

export function AdminPlataformaPanel({
  token,
  empresas,
  empresaIdSeleccionada,
  onEmpresasActualizadas,
  onSeleccionarEmpresa,
}: Props) {
  const [msg, setMsg] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [desactivarId, setDesactivarId] = useState<number | null>(null);
  const [desactivando, setDesactivando] = useState(false);
  const [resumen, setResumen] = useState<ResumenEmpresa[]>([]);
  const [cargandoResumen, setCargandoResumen] = useState(true);
  const [busqueda, setBusqueda] = useState('');

  const [wizardOpen, setWizardOpen] = useState(false);
  const [wizardStep, setWizardStep] = useState(0);
  const [wizardEmpresaId, setWizardEmpresaId] = useState<number | null>(null);
  const [wizardLoading, setWizardLoading] = useState(false);

  const [nombre, setNombre] = useState('');
  const [telefono, setTelefono] = useState('');
  const [correo, setCorreo] = useState('');
  const [tarifaEquipaje, setTarifaEquipaje] = useState(100);
  const [logoUrl, setLogoUrl] = useState('');

  const [adminUsuario, setAdminUsuario] = useState('');
  const [adminNombre, setAdminNombre] = useState('');
  const [adminEmail, setAdminEmail] = useState('');
  const [adminPassword, setAdminPassword] = useState('password');

  const cargarResumen = useCallback(async () => {
    setCargandoResumen(true);
    try {
      setResumen(await resumenPlataforma(token));
    } catch {
      setResumen([]);
    } finally {
      setCargandoResumen(false);
    }
  }, [token]);

  useEffect(() => {
    cargarResumen();
  }, [cargarResumen, empresas.length]);

  const resumenPorId = useMemo(() => new Map(resumen.map((r) => [r.id, r])), [resumen]);

  const totales = useMemo(
    () => ({
      cooperativas: resumen.length,
      buses: resumen.reduce((s, r) => s + r.busesActivos, 0),
      viajes: resumen.reduce((s, r) => s + r.viajesHoy, 0),
      boletos: resumen.reduce((s, r) => s + r.boletosVendidosHoy, 0),
      sinAdmin: resumen.filter((r) => r.operadoresActivos === 0).length,
    }),
    [resumen]
  );

  const empresasFiltradas = useMemo(() => {
    const q = busqueda.trim().toLowerCase();
    if (!q) return empresas;
    return empresas.filter(
      (e) =>
        e.nombre.toLowerCase().includes(q) ||
        (e.correo ?? '').toLowerCase().includes(q) ||
        (e.telefono ?? '').includes(q)
    );
  }, [empresas, busqueda]);

  const empresaSeleccionada = empresas.find((e) => e.id === empresaIdSeleccionada);
  const coopSinAdmin =
    empresaIdSeleccionada !== '' &&
    (resumenPorId.get(empresaIdSeleccionada as number)?.operadoresActivos ?? 0) === 0;

  function resetWizardFields() {
    setWizardStep(0);
    setWizardEmpresaId(null);
    setNombre('');
    setTelefono('');
    setCorreo('');
    setTarifaEquipaje(100);
    setLogoUrl('');
    setAdminUsuario('');
    setAdminNombre('');
    setAdminEmail('');
    setAdminPassword('password');
  }

  function abrirWizardNueva() {
    resetWizardFields();
    setWizardOpen(true);
  }

  function abrirWizardSoloAdmin(empresaId: number, nombreCoop: string) {
    resetWizardFields();
    setWizardEmpresaId(empresaId);
    setWizardStep(1);
    setNombre(nombreCoop);
    setAdminUsuario(sugerirUsuarioAdmin(nombreCoop));
    onSeleccionarEmpresa(empresaId);
    setWizardOpen(true);
  }

  function cerrarWizard() {
    if (wizardLoading) return;
    setWizardOpen(false);
    resetWizardFields();
  }

  async function handleWizardPaso1() {
    setMsg(null);
    if (!nombre.trim()) {
      setMsg({ type: 'error', text: 'El nombre comercial es obligatorio (RN E1).' });
      return;
    }
    if (!correoValido(correo)) {
      setMsg({ type: 'error', text: 'El correo no tiene un formato válido (RN E2).' });
      return;
    }
    if (tarifaEquipaje < 0) {
      setMsg({ type: 'error', text: 'La tarifa de equipaje extra no puede ser negativa.' });
      return;
    }

    setWizardLoading(true);
    try {
      const creada = await crearEmpresa(token, {
        nombre: nombre.trim(),
        telefono: telefono.trim() || undefined,
        correo: correo.trim() || undefined,
        tarifaEquipajeExtra: tarifaEquipaje,
        logoUrl: logoUrl.trim() || undefined,
      });
      const list = await listarEmpresas(token);
      onEmpresasActualizadas(list, creada.id);
      onSeleccionarEmpresa(creada.id);
      setWizardEmpresaId(creada.id);
      setAdminUsuario(sugerirUsuarioAdmin(creada.nombre));
      setWizardStep(1);
      await cargarResumen();
    } catch (err) {
      setMsg({ type: 'error', text: err instanceof Error ? err.message : 'No se pudo crear la cooperativa' });
    } finally {
      setWizardLoading(false);
    }
  }

  async function handleWizardPaso2() {
    const empresaId = wizardEmpresaId ?? (empresaIdSeleccionada !== '' ? (empresaIdSeleccionada as number) : null);
    if (empresaId === null) {
      setMsg({ type: 'error', text: 'No hay cooperativa vinculada. Complete el paso 1 primero.' });
      return;
    }

    setWizardLoading(true);
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
      await cargarResumen();
      setMsg({ type: 'success', text: `Cooperativa activa: «${adminUsuario}» puede iniciar sesión.` });
      cerrarWizard();
    } catch (err) {
      setMsg({ type: 'error', text: err instanceof Error ? err.message : 'No se pudo crear el administrador' });
    } finally {
      setWizardLoading(false);
    }
  }

  async function confirmarDesactivar() {
    if (desactivarId === null) return;
    setDesactivando(true);
    setMsg(null);
    try {
      await desactivarEmpresa(token, desactivarId);
      const list = await listarEmpresas(token);
      const siguiente = list.find((e) => e.id !== desactivarId)?.id;
      onEmpresasActualizadas(list, siguiente);
      await cargarResumen();
      setMsg({ type: 'success', text: 'Cooperativa desactivada correctamente (RN E4).' });
    } catch (err) {
      setMsg({ type: 'error', text: err instanceof Error ? err.message : 'No se pudo desactivar' });
    } finally {
      setDesactivando(false);
      setDesactivarId(null);
    }
  }

  const empresaDesactivar = empresas.find((e) => e.id === desactivarId);
  const nombreCoopWizard =
    empresas.find((e) => e.id === wizardEmpresaId)?.nombre ?? (nombre.trim() || 'la cooperativa');

  return (
    <Box className="platform-coops-pro">
      {cargandoResumen ? (
        <Box display="flex" justifyContent="center" py={3}>
          <CircularProgress size={28} />
        </Box>
      ) : (
        <Grid container spacing={2} sx={{ mb: 2.5 }}>
          <Grid item xs={6} md={3}>
            <StatCard
              compact
              label="Cooperativas"
              value={totales.cooperativas}
              icon={<BusinessIcon />}
              accent="#0f766e"
              hint={totales.sinAdmin > 0 ? `${totales.sinAdmin} pendientes de admin` : 'Activas en plataforma'}
            />
          </Grid>
          <Grid item xs={6} md={3}>
            <StatCard compact label="Flota total" value={totales.buses} icon={<DirectionsBusIcon />} accent="#0c4a6e" />
          </Grid>
          <Grid item xs={6} md={3}>
            <StatCard compact label="Viajes hoy" value={totales.viajes} icon={<EventNoteIcon />} accent="#7c3aed" />
          </Grid>
          <Grid item xs={6} md={3}>
            <StatCard compact label="Boletos hoy" value={totales.boletos} icon={<ConfirmationNumberIcon />} accent="#0369a1" />
          </Grid>
        </Grid>
      )}

      {msg && (
        <Alert severity={msg.type} sx={{ mb: 2 }} onClose={() => setMsg(null)}>
          {msg.text}
        </Alert>
      )}

      <Card className="platform-coops-shell">
        <Box className="platform-coops-layout">
          <Box className="platform-coops-sidebar">
            <Box className="platform-coops-sidebar__head">
              <Typography variant="subtitle2" fontWeight={700}>
                Cooperativas
              </Typography>
              <Typography variant="caption" color="text.secondary">
                {empresas.length} registradas
              </Typography>
              <TextField
                fullWidth
                size="small"
                placeholder="Buscar por nombre o contacto…"
                value={busqueda}
                onChange={(e) => setBusqueda(e.target.value)}
                sx={{ mt: 1.5 }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <SearchIcon fontSize="small" color="action" />
                    </InputAdornment>
                  ),
                }}
              />
              <Button
                fullWidth
                variant="contained"
                size="small"
                startIcon={<AddBusinessIcon />}
                onClick={abrirWizardNueva}
                sx={{ mt: 1.25 }}
              >
                Nueva cooperativa
              </Button>
            </Box>

            <Divider />

            <Box className="platform-coop-list">
              {empresas.length === 0 ? (
                <Box className="platform-coop-list__empty">
                  <Typography variant="body2" color="text.secondary">
                    No hay cooperativas aún.
                  </Typography>
                </Box>
              ) : empresasFiltradas.length === 0 ? (
                <Box className="platform-coop-list__empty">
                  <Typography variant="body2" color="text.secondary">
                    Sin coincidencias para «{busqueda}»
                  </Typography>
                </Box>
              ) : (
                empresasFiltradas.map((em) => {
                  const stats = resumenPorId.get(em.id);
                  const sinAdmin = (stats?.operadoresActivos ?? 0) === 0;
                  const selected = em.id === empresaIdSeleccionada;
                  return (
                    <Box
                      key={em.id}
                      role="button"
                      tabIndex={0}
                      className={`platform-coop-item${selected ? ' platform-coop-item--selected' : ''}`}
                      onClick={() => onSeleccionarEmpresa(em.id)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' || e.key === ' ') {
                          e.preventDefault();
                          onSeleccionarEmpresa(em.id);
                        }
                      }}
                    >
                      <Avatar
                        className="platform-coop-item__avatar"
                        sx={{ bgcolor: avatarColor(em.id) }}
                      >
                        {iniciales(em.nombre)}
                      </Avatar>
                      <Box className="platform-coop-item__body">
                        <Stack direction="row" alignItems="center" spacing={0.5}>
                          <Typography variant="body2" fontWeight={selected ? 700 : 600} noWrap>
                            {em.nombre}
                          </Typography>
                          {sinAdmin && (
                            <WarningAmberIcon sx={{ fontSize: 15, color: 'warning.main', flexShrink: 0 }} />
                          )}
                        </Stack>
                        {stats && (
                          <Typography variant="caption" color="text.secondary" noWrap display="block">
                            {stats.busesActivos} buses · {stats.boletosVendidosHoy} ventas hoy
                          </Typography>
                        )}
                      </Box>
                      <ChevronRightIcon className="platform-coop-item__chevron" sx={{ fontSize: 18, opacity: selected ? 1 : 0.35 }} />
                    </Box>
                  );
                })
              )}
            </Box>
          </Box>

          <Box className="platform-coops-main">
            {empresaIdSeleccionada !== '' && empresaSeleccionada ? (
              <CooperativaDetallePanel
                embedded
                token={token}
                empresaId={empresaIdSeleccionada as number}
                sinAdmin={coopSinAdmin}
                onAsignarAdmin={() => abrirWizardSoloAdmin(empresaSeleccionada.id, empresaSeleccionada.nombre)}
                onDesactivar={() => setDesactivarId(empresaSeleccionada.id)}
                canDesactivar={empresas.length > 1}
                onEmpresaActualizada={(e) => {
                  onEmpresasActualizadas(
                    empresas.map((em) => (em.id === e.id ? e : em)),
                    e.id
                  );
                }}
                onRecargarLista={cargarResumen}
              />
            ) : (
              <Box className="platform-coop-empty-state">
                <Box className="platform-coop-empty-state__icon">
                  <BusinessIcon />
                </Box>
                <Typography variant="subtitle1" fontWeight={700} gutterBottom>
                  Seleccione una cooperativa
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ maxWidth: 320 }}>
                  Elija una cooperativa del panel izquierdo para administrar accesos, datos comerciales y flota.
                </Typography>
              </Box>
            )}
          </Box>
        </Box>
      </Card>

      <Dialog open={wizardOpen} onClose={cerrarWizard} maxWidth="sm" fullWidth PaperProps={{ className: 'admin-dialog' }}>
        <DialogTitle>
          <Typography variant="h6" fontWeight={700}>
            Registrar cooperativa
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Complete los dos pasos para dejar la cooperativa operativa.
          </Typography>
        </DialogTitle>
        <DialogContent>
          <Stepper activeStep={wizardStep} alternativeLabel sx={{ mb: 3, mt: 1 }}>
            {PASOS.map((label) => (
              <Step key={label}>
                <StepLabel>{label}</StepLabel>
              </Step>
            ))}
          </Stepper>

          {wizardStep === 0 && (
            <Stack spacing={2}>
              <TextField fullWidth required autoFocus label="Nombre comercial" value={nombre} onChange={(e) => setNombre(e.target.value)} />
              <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
                <TextField fullWidth label="Teléfono" value={telefono} onChange={(e) => setTelefono(e.target.value)} />
                <TextField fullWidth type="email" label="Correo de contacto" value={correo} onChange={(e) => setCorreo(e.target.value)} />
              </Stack>
              <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
                <TextField
                  fullWidth
                  type="number"
                  inputProps={{ min: 0 }}
                  label="Equipaje extra (C$)"
                  value={tarifaEquipaje}
                  onChange={(e) => setTarifaEquipaje(Number(e.target.value))}
                />
                <TextField fullWidth label="URL del logo" value={logoUrl} onChange={(e) => setLogoUrl(e.target.value)} />
              </Stack>
            </Stack>
          )}

          {wizardStep === 1 && (
            <Stack spacing={2}>
              <Alert severity="info" icon={false} sx={{ py: 1 }}>
                Primer administrador de <strong>{nombreCoopWizard}</strong>
              </Alert>
              <TextField fullWidth required autoFocus label="Usuario de login" value={adminUsuario} onChange={(e) => setAdminUsuario(e.target.value)} helperText="Campo de acceso personal — no es el correo comercial" />
              <TextField fullWidth required label="Nombre completo" value={adminNombre} onChange={(e) => setAdminNombre(e.target.value)} />
              <TextField fullWidth type="email" label="Email Keycloak (opcional)" value={adminEmail} onChange={(e) => setAdminEmail(e.target.value)} />
              <TextField fullWidth required type="password" label="Contraseña inicial" value={adminPassword} onChange={(e) => setAdminPassword(e.target.value)} />
            </Stack>
          )}
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2.5 }}>
          <Button onClick={cerrarWizard} disabled={wizardLoading}>
            Cancelar
          </Button>
          {wizardStep === 1 && wizardEmpresaId === null && (
            <Button onClick={() => setWizardStep(0)} disabled={wizardLoading}>
              Atrás
            </Button>
          )}
          {wizardStep === 0 ? (
            <Button variant="contained" onClick={handleWizardPaso1} disabled={wizardLoading}>
              {wizardLoading ? 'Guardando…' : 'Continuar'}
            </Button>
          ) : (
            <Button variant="contained" onClick={handleWizardPaso2} disabled={wizardLoading}>
              {wizardLoading ? 'Creando…' : 'Finalizar registro'}
            </Button>
          )}
        </DialogActions>
      </Dialog>

      <Dialog open={desactivarId !== null} onClose={() => !desactivando && setDesactivarId(null)}>
        <DialogTitle>Desactivar cooperativa</DialogTitle>
        <DialogContent>
          <DialogContentText>
            ¿Confirma desactivar <strong>{empresaDesactivar?.nombre}</strong>? Dejará de mostrarse en consulta pública.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDesactivarId(null)} disabled={desactivando}>
            Cancelar
          </Button>
          <Button color="warning" variant="contained" onClick={confirmarDesactivar} disabled={desactivando}>
            {desactivando ? 'Procesando…' : 'Desactivar'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
