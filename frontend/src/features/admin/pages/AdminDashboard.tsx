import { useEffect, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  CircularProgress,
  Grid,
  MenuItem,
  TextField,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import { ListaPasajeros } from '@/features/admin/components/ListaPasajeros';
import { AdminFlotaLista } from '@/features/admin/components/AdminFlotaLista';
import { AdminViajesLista } from '@/features/admin/components/AdminViajesLista';
import { AdminParadasRuta } from '@/features/admin/components/AdminParadasRuta';
import { AdminOperadores } from '@/features/admin/components/AdminOperadores';
import { AdminPlataformaPanel } from '@/features/admin/components/AdminPlataformaPanel';
import { PerfilEmpresaForm } from '@/features/admin/components/PerfilEmpresaForm';
import { ReporteOcupacion } from '@/features/reportes/components/ReporteOcupacion';
import { ReporteIngresos } from '@/features/reportes/components/ReporteIngresos';
import {
  busesMiEmpresa,
  busesPorEmpresa,
  crearBus,
  listarEmpresas,
  miEmpresa,
  programarViaje,
  viajesMiEmpresa,
  viajesPorEmpresa,
  type Bus,
  type Empresa,
  type ViajeOperador,
} from '@/shared/api';
import { useAuth } from '@/features/auth/AuthContext';
import { fechaHoyLocal, componerHoraBackend, HORA_SALIDA_DEFAULT, type HoraSalidaNicaragua } from '@/shared/utils/formato';
import { HoraSalidaField } from '@/shared/ui/HoraSalidaField';
import { CIUDADES_CORREDOR, destinoOpuesto, type CiudadCorredor } from '@/shared/utils/corredor';
import { ROLES } from '@/shared/utils/jwt';
import { AdminShell } from '@/features/admin/components/AdminShell';
import type { AdminSectionId } from '@/features/admin/components/AdminNav';
import { TenantSelector } from '@/features/admin/components/TenantSelector';
import { SectionCard } from '@/shared/ui/SectionCard';

export default function AdminDashboard() {
  const { token, hasRole } = useAuth();
  const esGlobal = hasRole(ROLES.ADMIN_GENERAL);

  const defaultSection: AdminSectionId = esGlobal ? 'plataforma' : 'perfil';
  const [section, setSection] = useState<AdminSectionId>(defaultSection);
  const [empresas, setEmpresas] = useState<Empresa[]>([]);
  const [empresaId, setEmpresaId] = useState<number | ''>('');
  const [empresaNombre, setEmpresaNombre] = useState('');
  const [buses, setBuses] = useState<Bus[]>([]);
  const [viajes, setViajes] = useState<ViajeOperador[]>([]);
  const [fechaViajes, setFechaViajes] = useState(fechaHoyLocal());
  const [loading, setLoading] = useState(true);
  const [msg, setMsg] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const [busNumero, setBusNumero] = useState('');
  const [busPlaca, setBusPlaca] = useState('');
  const [busCapacidad, setBusCapacidad] = useState(50);
  const [busSede, setBusSede] = useState<CiudadCorredor>('Bluefields');
  const [busFotoUrl, setBusFotoUrl] = useState('');

  const [viajeOrigen, setViajeOrigen] = useState<CiudadCorredor>('Bluefields');
  const [viajeDestino, setViajeDestino] = useState<CiudadCorredor>('Managua');
  const [viajeBusId, setViajeBusId] = useState<number | ''>('');
  const [viajeHora, setViajeHora] = useState<HoraSalidaNicaragua>(HORA_SALIDA_DEFAULT);
  const [viajeTarifa, setViajeTarifa] = useState(350);
  const [viajeFecha, setViajeFecha] = useState(fechaHoyLocal());
  const [filtroOrigenViajes, setFiltroOrigenViajes] = useState('');

  const requiereTenant = section !== 'plataforma' && section !== 'paradas';

  useEffect(() => {
    if (!token) return;

    async function init() {
      if (!token) return;
      const authToken = token;
      setLoading(true);
      try {
        if (esGlobal) {
          const list = await listarEmpresas(authToken);
          setEmpresas(list);
          if (list.length > 0) {
            setEmpresaId(list[0].id);
            setEmpresaNombre(list[0].nombre);
          }
        } else {
          const tenant = await miEmpresa(authToken);
          setEmpresaId(tenant.id);
          setEmpresaNombre(tenant.nombre);
        }
      } catch (e) {
        setMsg({ type: 'error', text: e instanceof Error ? e.message : 'Error' });
      } finally {
        setLoading(false);
      }
    }

    init();
  }, [token, esGlobal]);

  useEffect(() => {
    if (!token || empresaId === '') return;
    cargarDatos();
  }, [token, empresaId, fechaViajes, filtroOrigenViajes, esGlobal]);

  const busesEnOrigen = buses.filter((b) => b.sede === viajeOrigen);

  useEffect(() => {
    if (busesEnOrigen.length === 0) {
      setViajeBusId('');
      return;
    }
    if (!busesEnOrigen.some((b) => b.id === viajeBusId)) {
      setViajeBusId(busesEnOrigen[0].id);
    }
  }, [busesEnOrigen, viajeBusId, viajeOrigen]);

  async function cargarDatos() {
    if (!token || empresaId === '') return;
    try {
      const origenFiltro = filtroOrigenViajes || undefined;
      const [b, v] = await Promise.all([
        esGlobal ? busesPorEmpresa(token, empresaId as number) : busesMiEmpresa(token),
        esGlobal
          ? viajesPorEmpresa(token, empresaId as number, fechaViajes, origenFiltro)
          : viajesMiEmpresa(token, fechaViajes, origenFiltro),
      ]);
      setBuses(b);
      setViajes(v);
    } catch (e) {
      setMsg({ type: 'error', text: e instanceof Error ? e.message : 'Error al cargar' });
    }
  }

  async function handleCrearBus(e: React.FormEvent) {
    e.preventDefault();
    if (!token || empresaId === '') return;
    setMsg(null);

    if (busCapacidad <= 0 || busCapacidad % 2 !== 0) {
      setMsg({ type: 'error', text: 'La capacidad debe ser un número par mayor a 0 (RN BU2).' });
      return;
    }

    try {
      await crearBus(token, {
        empresaId: empresaId as number,
        numeroInterno: busNumero,
        placa: busPlaca,
        capacidad: busCapacidad,
        sede: busSede,
        fotoUrl: busFotoUrl || undefined,
      });
      setMsg({ type: 'success', text: 'Bus registrado con asientos generados' });
      setBusNumero('');
      setBusPlaca('');
      setBusFotoUrl('');
      cargarDatos();
    } catch (e) {
      setMsg({ type: 'error', text: e instanceof Error ? e.message : 'Error' });
    }
  }

  async function handleProgramarViaje(e: React.FormEvent) {
    e.preventDefault();
    if (!token || empresaId === '' || !viajeBusId) return;
    setMsg(null);

    if (viajeOrigen === viajeDestino) {
      setMsg({ type: 'error', text: 'Origen y destino deben ser distintos.' });
      return;
    }
    if (!viajeFecha || !viajeHora.hora) {
      setMsg({ type: 'error', text: 'Fecha y hora de salida son obligatorias (RN V1).' });
      return;
    }
    if (viajeTarifa < 0) {
      setMsg({ type: 'error', text: 'La tarifa no puede ser negativa (RN V2).' });
      return;
    }

    try {
      await programarViaje(token, {
        empresaId: empresaId as number,
        busId: viajeBusId as number,
        origen: viajeOrigen,
        destino: viajeDestino,
        fecha: viajeFecha,
        horaSalida: componerHoraBackend(viajeHora),
        tarifa: viajeTarifa,
      });
      setMsg({ type: 'success', text: 'Viaje programado' });
      cargarDatos();
    } catch (e) {
      setMsg({ type: 'error', text: e instanceof Error ? e.message : 'Error' });
    }
  }

  function actualizarEmpresas(list: Empresa[], seleccionarId?: number) {
    setEmpresas(list);
    if (seleccionarId !== undefined) {
      setEmpresaId(seleccionarId);
      const sel = list.find((em) => em.id === seleccionarId);
      setEmpresaNombre(sel?.nombre ?? '');
    } else if (list.length === 0) {
      setEmpresaId('');
      setEmpresaNombre('');
    } else if (empresaId !== '' && !list.some((em) => em.id === empresaId)) {
      setEmpresaId(list[0].id);
      setEmpresaNombre(list[0].nombre);
    }
  }

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" height="100vh">
        <CircularProgress />
      </Box>
    );
  }

  const tenantBar =
    (section !== 'plataforma' || !esGlobal) && (
      <TenantSelector
        esGlobal={esGlobal}
        empresas={empresas}
        empresaId={empresaId}
        empresaNombre={empresaNombre}
        onChange={(id, nombre) => {
          setEmpresaId(id);
          setEmpresaNombre(nombre);
        }}
        compact
      />
    );

  return (
    <AdminShell
      esGlobal={esGlobal}
      section={section}
      onSectionChange={setSection}
      sidebarFooter={
        esGlobal && section !== 'plataforma' ? (
          <TenantSelector
            esGlobal={esGlobal}
            empresas={empresas}
            empresaId={empresaId}
            empresaNombre={empresaNombre}
            onChange={(id, nombre) => {
              setEmpresaId(id);
              setEmpresaNombre(nombre);
            }}
            compact
            sidebar
          />
        ) : undefined
      }
      topBarExtra={tenantBar}
    >
      {msg && (
        <Alert severity={msg.type} sx={{ mb: 2 }} onClose={() => setMsg(null)}>
          {msg.text}
        </Alert>
      )}

      {esGlobal && section === 'plataforma' && token && (
        <AdminPlataformaPanel
          token={token}
          empresas={empresas}
          empresaIdSeleccionada={empresaId}
          onEmpresasActualizadas={actualizarEmpresas}
          onSeleccionarEmpresa={(id) => {
            setEmpresaId(id);
            const sel = empresas.find((em) => em.id === id);
            setEmpresaNombre(sel?.nombre ?? '');
          }}
        />
      )}

      {requiereTenant && empresaId === '' && esGlobal && (
        <Alert severity="info">Seleccione o registre una cooperativa para usar esta sección.</Alert>
      )}

      {section === 'perfil' && token && empresaId !== '' && (
        <PerfilEmpresaForm
          token={token}
          empresaId={empresaId as number}
          esGlobal={esGlobal}
          onActualizado={(e) => setEmpresaNombre(e.nombre)}
        />
      )}

      {section === 'buses' && empresaId !== '' && (
        <Grid container spacing={3}>
          <Grid item xs={12} md={5}>
            <SectionCard title="Nuevo bus" subtitle="Registro con asientos zigzag automáticos">
              <Box component="form" onSubmit={handleCrearBus}>
                <TextField
                  fullWidth
                  required
                  label="Número interno"
                  margin="dense"
                  value={busNumero}
                  onChange={(e) => setBusNumero(e.target.value)}
                />
                <TextField
                  fullWidth
                  required
                  label="Placa"
                  margin="dense"
                  value={busPlaca}
                  onChange={(e) => setBusPlaca(e.target.value)}
                  helperText="Placa única en todo el sistema (RN BU3)"
                />
                <TextField
                  fullWidth
                  required
                  type="number"
                  inputProps={{ min: 50, max: 50 }}
                  label="Capacidad"
                  margin="dense"
                  value={busCapacidad}
                  onChange={(e) => setBusCapacidad(Number(e.target.value))}
                  helperText="50 asientos zigzag (RN BU2: capacidad par). 1V·2P, 3P·4V… fila trasera 46–50"
                />
                <TextField
                  fullWidth
                  select
                  required
                  label="Terminal base (sede)"
                  margin="dense"
                  value={busSede}
                  onChange={(e) => setBusSede(e.target.value as CiudadCorredor)}
                  helperText="Ciudad donde opera este bus normalmente"
                >
                  {CIUDADES_CORREDOR.map((c) => (
                    <MenuItem key={c} value={c}>
                      {c}
                    </MenuItem>
                  ))}
                </TextField>
                <TextField
                  fullWidth
                  label="URL foto del bus (opcional)"
                  margin="dense"
                  placeholder="/images/bus-yutong-interurbano.png"
                  value={busFotoUrl}
                  onChange={(e) => setBusFotoUrl(e.target.value)}
                />
                <Button type="submit" variant="contained" startIcon={<AddIcon />} sx={{ mt: 2 }}>
                  Registrar bus
                </Button>
              </Box>
            </SectionCard>
          </Grid>
          <Grid item xs={12} md={7}>
            <SectionCard title={`Flota (${buses.length})`}>
                <AdminFlotaLista
                  token={token!}
                  buses={buses}
                  onActualizado={cargarDatos}
                  onMsg={setMsg}
                />
            </SectionCard>
          </Grid>
        </Grid>
      )}

      {section === 'viajes' && empresaId !== '' && (
        <Grid container spacing={3}>
          <Grid item xs={12} md={5}>
            <SectionCard title="Programar viaje" subtitle="Salidas Bluefields ↔ Managua">
              <Box component="form" onSubmit={handleProgramarViaje}>
                <TextField
                  fullWidth
                  select
                  required
                  label="Origen"
                  margin="dense"
                  value={viajeOrigen}
                  onChange={(e) => {
                    const origen = e.target.value as CiudadCorredor;
                    setViajeOrigen(origen);
                    setViajeDestino(destinoOpuesto(origen));
                  }}
                >
                  {CIUDADES_CORREDOR.map((c) => (
                    <MenuItem key={c} value={c}>
                      {c}
                    </MenuItem>
                  ))}
                </TextField>
                <TextField
                  fullWidth
                  select
                  required
                  label="Destino"
                  margin="dense"
                  value={viajeDestino}
                  onChange={(e) => setViajeDestino(e.target.value as CiudadCorredor)}
                >
                  {CIUDADES_CORREDOR.filter((c) => c !== viajeOrigen).map((c) => (
                    <MenuItem key={c} value={c}>
                      {c}
                    </MenuItem>
                  ))}
                </TextField>
                <TextField
                  fullWidth
                  select
                  required
                  label="Bus (sede origen)"
                  margin="dense"
                  value={viajeBusId}
                  onChange={(e) => setViajeBusId(Number(e.target.value))}
                  helperText={
                    busesEnOrigen.length === 0
                      ? `No hay buses con sede ${viajeOrigen}. Regístrelo en la pestaña Buses.`
                      : `Solo buses basados en ${viajeOrigen}`
                  }
                >
                  {busesEnOrigen.map((b) => (
                    <MenuItem key={b.id} value={b.id}>
                      {b.numeroInterno} ({b.placa}) · {b.sede}
                    </MenuItem>
                  ))}
                </TextField>
                <TextField
                  fullWidth
                  type="date"
                  label="Fecha"
                  margin="dense"
                  InputLabelProps={{ shrink: true }}
                  value={viajeFecha}
                  onChange={(e) => setViajeFecha(e.target.value)}
                />
                <HoraSalidaField value={viajeHora} onChange={setViajeHora} />
                <TextField
                  fullWidth
                  type="number"
                  inputProps={{ min: 0 }}
                  label="Tarifa C$"
                  margin="dense"
                  value={viajeTarifa}
                  onChange={(e) => setViajeTarifa(Number(e.target.value))}
                  helperText="Tarifa única ≥ 0 (RN V2)"
                />
                <Button
                  type="submit"
                  variant="contained"
                  startIcon={<AddIcon />}
                  sx={{ mt: 2 }}
                  disabled={!viajeBusId}
                >
                  Programar
                </Button>
              </Box>
            </SectionCard>
          </Grid>
          <Grid item xs={12} md={7}>
            <SectionCard
              title="Viajes programados"
              subtitle="Filtre por fecha y terminal de salida"
            >
              <Box display="flex" gap={2} flexWrap="wrap" alignItems="center" mb={2}>
                  <TextField
                    select
                    size="small"
                    label="Salidas desde"
                    value={filtroOrigenViajes}
                    onChange={(e) => setFiltroOrigenViajes(e.target.value)}
                    sx={{ minWidth: 160 }}
                  >
                    <MenuItem value="">Todas</MenuItem>
                    {CIUDADES_CORREDOR.map((c) => (
                      <MenuItem key={c} value={c}>
                        {c}
                      </MenuItem>
                    ))}
                  </TextField>
                  <TextField
                    type="date"
                    size="small"
                    value={fechaViajes}
                    onChange={(e) => setFechaViajes(e.target.value)}
                    InputLabelProps={{ shrink: true }}
                  />
                </Box>
                <AdminViajesLista
                  token={token!}
                  viajes={viajes}
                  onActualizado={cargarDatos}
                  onMsg={setMsg}
                />
            </SectionCard>
          </Grid>
        </Grid>
      )}

      {!esGlobal && section === 'operadores' && token && empresaId !== '' && (
        <AdminOperadores token={token} empresaId={empresaId as number} />
      )}

      {!esGlobal && section === 'pasajeros' && token && empresaId !== '' && (
        <ListaPasajeros token={token} empresaId={empresaId as number} />
      )}

      {section === 'ocupacion' && token && empresaId !== '' && (
        <ReporteOcupacion token={token} empresaId={empresaId as number} esGlobal={esGlobal} />
      )}

      {section === 'ingresos' && token && empresaId !== '' && (
        <ReporteIngresos token={token} empresaId={empresaId as number} esGlobal={esGlobal} />
      )}

      {section === 'paradas' && token && <AdminParadasRuta token={token} />}
    </AdminShell>
  );
}
