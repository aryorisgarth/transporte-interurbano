import { useCallback, useEffect, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  ButtonGroup,
  Card,
  CardContent,
  CircularProgress,
  Grid,
  Link,
  MenuItem,
  TextField,
  Typography,
} from '@mui/material';
import SaveIcon from '@mui/icons-material/Save';
import AddLocationIcon from '@mui/icons-material/AddLocation';
import DeleteIcon from '@mui/icons-material/Delete';
import EditLocationIcon from '@mui/icons-material/EditLocation';
import { MapaParadasLeaflet, urlGoogleMapsPunto } from '@/shared/maps/MapaParadasLeaflet';
import { MapaRuta } from '@/shared/maps/MapaRuta';
import {
  actualizarParada,
  crearParada,
  eliminarParada,
  listarParadas,
  type ParadaRuta,
} from '@/shared/api';
import { CIUDADES_CORREDOR, destinoOpuesto, type CiudadCorredor } from '@/shared/utils/corredor';
import { formatearHoraNicaragua, componerHoraBackend, HORA_SALIDA_DEFAULT, type HoraSalidaNicaragua } from '@/shared/utils/formato';
import { HoraSalidaField } from '@/shared/ui/HoraSalidaField';

interface Props {
  token: string;
}

type ModoMapa = 'mover' | 'agregar';

interface ParadaEditable extends ParadaRuta {
  minutosDesdeSalida?: number;
  _dirty?: boolean;
}

export function AdminParadasRuta({ token }: Props) {
  const [origen, setOrigen] = useState<CiudadCorredor>('Bluefields');
  const [destino, setDestino] = useState<CiudadCorredor>('Managua');
  const [horaSalida, setHoraSalida] = useState<HoraSalidaNicaragua>(HORA_SALIDA_DEFAULT);
  const [paradas, setParadas] = useState<ParadaEditable[]>([]);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [modoMapa, setModoMapa] = useState<ModoMapa>('mover');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState<{ type: 'success' | 'error' | 'info'; text: string } | null>(null);

  const cargar = useCallback(async () => {
    setLoading(true);
    try {
      const hora24 = componerHoraBackend(horaSalida);
      const hora = hora24.length === 5 ? `${hora24}:00` : hora24;
      const data = await listarParadas(token, origen, destino, hora);
      setParadas(data);
      setSelectedId((prev) => (data.length > 0 && !data.some((p) => p.id === prev) ? data[0].id : prev));
    } catch {
      setParadas([]);
      setSelectedId(null);
    } finally {
      setLoading(false);
    }
  }, [token, origen, destino, horaSalida]);

  useEffect(() => {
    cargar();
  }, [cargar]);

  function actualizarCampo(id: number, campo: keyof ParadaEditable, valor: string | number) {
    setParadas((prev) =>
      prev.map((p) => (p.id === id ? { ...p, [campo]: valor, _dirty: true } : p))
    );
  }

  function moverParadaEnMapa(id: number, lat: number, lng: number) {
    setParadas((prev) =>
      prev.map((p) => (p.id === id ? { ...p, latitud: lat, longitud: lng, _dirty: true } : p))
    );
    setSelectedId(id);
    setMsg({ type: 'info', text: 'Posición actualizada. Pulse "Guardar parada" para confirmar.' });
  }

  async function handleClicMapa(lat: number, lng: number) {
    if (modoMapa === 'agregar') {
      setSaving(true);
      setMsg(null);
      try {
        const nombre = `Parada ${paradas.length + 1}`;
        const minutos =
          paradas.length === 0
            ? 0
            : Math.max(...paradas.map((p) => p.minutosDesdeSalida ?? 0)) + 30;

        await crearParada(token, {
          origen,
          destino,
          nombre,
          minutosDesdeSalida: minutos,
          latitud: lat,
          longitud: lng,
        });
        setMsg({ type: 'success', text: `Parada "${nombre}" agregada. Edite el nombre y guarde si desea.` });
        await cargar();
      } catch (err) {
        setMsg({ type: 'error', text: err instanceof Error ? err.message : 'Error al agregar parada' });
      } finally {
        setSaving(false);
      }
      return;
    }

    if (selectedId == null) {
      setMsg({ type: 'error', text: 'Seleccione una parada de la lista, o use modo "Agregar parada".' });
      return;
    }
    moverParadaEnMapa(selectedId, lat, lng);
  }

  async function guardarParada(p: ParadaEditable) {
    if (p.latitud == null || p.longitud == null) {
      setMsg({ type: 'error', text: 'Coloque la parada en el mapa (clic o arrastre del marcador)' });
      return;
    }
    setSaving(true);
    setMsg(null);
    try {
      await actualizarParada(token, p.id, {
        nombre: p.nombre,
        minutosDesdeSalida: p.minutosDesdeSalida ?? 0,
        latitud: p.latitud,
        longitud: p.longitud,
      });
      setMsg({ type: 'success', text: `Parada "${p.nombre}" guardada` });
      await cargar();
    } catch (err) {
      setMsg({ type: 'error', text: err instanceof Error ? err.message : 'Error al guardar' });
    } finally {
      setSaving(false);
    }
  }

  async function borrarParada(p: ParadaEditable) {
    if (!window.confirm(`¿Eliminar "${p.nombre}" de la ruta?`)) return;
    setSaving(true);
    setMsg(null);
    try {
      await eliminarParada(token, p.id);
      setMsg({ type: 'success', text: 'Parada eliminada' });
      await cargar();
    } catch (err) {
      setMsg({ type: 'error', text: err instanceof Error ? err.message : 'Error al eliminar' });
    } finally {
      setSaving(false);
    }
  }

  return (
    <Box>
      <Alert severity="info" sx={{ mb: 2 }}>
        <strong>Arme su ruta real:</strong> elimine paradas que no usan (ej. El Rama) y agregue solo las suyas
        (ej. Bluefields → Nueva Guinea → Managua). Arrastre los marcadores o haga clic en el mapa.
      </Alert>

      <Grid container spacing={2} sx={{ mb: 2 }}>
        <Grid item xs={12} sm={3}>
          <TextField
            select
            fullWidth
            size="small"
            label="Origen"
            value={origen}
            onChange={(e) => {
              const o = e.target.value as CiudadCorredor;
              setOrigen(o);
              setDestino(destinoOpuesto(o));
            }}
          >
            {CIUDADES_CORREDOR.map((c) => (
              <MenuItem key={c} value={c}>
                {c}
              </MenuItem>
            ))}
          </TextField>
        </Grid>
        <Grid item xs={12} sm={3}>
          <TextField
            select
            fullWidth
            size="small"
            label="Destino"
            value={destino}
            onChange={(e) => setDestino(e.target.value as CiudadCorredor)}
          >
            {CIUDADES_CORREDOR.filter((c) => c !== origen).map((c) => (
              <MenuItem key={c} value={c}>
                {c}
              </MenuItem>
            ))}
          </TextField>
        </Grid>
        <Grid item xs={12} sm={3}>
          <HoraSalidaField
            value={horaSalida}
            onChange={setHoraSalida}
            label="Hora salida referencia"
            size="small"
          />
        </Grid>
      </Grid>

      {msg && (
        <Alert severity={msg.type} sx={{ mb: 2 }} onClose={() => setMsg(null)}>
          {msg.text}
        </Alert>
      )}

      {loading ? (
        <Box display="flex" justifyContent="center" py={4}>
          <CircularProgress />
        </Box>
      ) : (
        <Grid container spacing={3}>
          <Grid item xs={12} md={7}>
            <Box display="flex" justifyContent="space-between" alignItems="center" mb={1} flexWrap="wrap" gap={1}>
              <Typography variant="subtitle2">Mapa — edite la ruta aquí</Typography>
              <ButtonGroup size="small" variant="outlined">
                <Button
                  variant={modoMapa === 'mover' ? 'contained' : 'outlined'}
                  startIcon={<EditLocationIcon />}
                  onClick={() => setModoMapa('mover')}
                >
                  Mover parada
                </Button>
                <Button
                  variant={modoMapa === 'agregar' ? 'contained' : 'outlined'}
                  startIcon={<AddLocationIcon />}
                  onClick={() => setModoMapa('agregar')}
                >
                  Agregar parada
                </Button>
              </ButtonGroup>
            </Box>
            <Typography variant="caption" color="text.secondary" display="block" sx={{ mb: 1 }}>
              {modoMapa === 'agregar'
                ? 'Clic en el mapa = nueva parada en esa ubicación'
                : 'Seleccione parada → arrastre el marcador o clic en el mapa para reposicionar'}
            </Typography>
            <MapaParadasLeaflet
              paradas={paradas}
              height={420}
              editable
              selectedId={selectedId}
              onMapClick={handleClicMapa}
              onMarkerDrag={moverParadaEnMapa}
            />
          </Grid>

          <Grid item xs={12} md={5}>
            <Typography variant="subtitle2" gutterBottom>
              Paradas ({paradas.length}) — mínimo 2 (salida y llegada)
            </Typography>
            {paradas.length === 0 ? (
              <Alert severity="warning">
                Sin paradas. Use <strong>Agregar parada</strong> y haga clic en el mapa para marcar salida,
                destinos intermedios y llegada.
              </Alert>
            ) : (
              paradas.map((p) => (
                <Card
                  key={p.id}
                  variant={selectedId === p.id ? 'elevation' : 'outlined'}
                  sx={{
                    mb: 2,
                    border: selectedId === p.id ? 2 : 1,
                    borderColor: selectedId === p.id ? 'primary.main' : 'divider',
                    cursor: 'pointer',
                    bgcolor: p._dirty ? 'action.hover' : undefined,
                  }}
                  onClick={() => {
                    setSelectedId(p.id);
                    setModoMapa('mover');
                  }}
                >
                  <CardContent sx={{ py: 1.5, '&:last-child': { pb: 1.5 } }}>
                    <Typography variant="subtitle2">
                      {p.orden}. {p.nombre}
                      {p._dirty && ' *'}
                      {p.horaEstimada && (
                        <Typography component="span" variant="body2" color="text.secondary">
                          {' '}
                          · {formatearHoraNicaragua(p.horaEstimada + ':00')}
                        </Typography>
                      )}
                    </Typography>
                    <TextField
                      fullWidth
                      size="small"
                      label="Nombre (ej. Nueva Guinea)"
                      margin="dense"
                      value={p.nombre}
                      onClick={(e) => e.stopPropagation()}
                      onChange={(e) => actualizarCampo(p.id, 'nombre', e.target.value)}
                    />
                    <TextField
                      fullWidth
                      size="small"
                      label="Minutos desde salida"
                      type="number"
                      margin="dense"
                      value={p.minutosDesdeSalida ?? 0}
                      onClick={(e) => e.stopPropagation()}
                      onChange={(e) => actualizarCampo(p.id, 'minutosDesdeSalida', Number(e.target.value))}
                    />
                    <Box display="flex" gap={1}>
                      <TextField
                        size="small"
                        label="Latitud"
                        type="number"
                        inputProps={{ step: '0.0001' }}
                        value={p.latitud ?? ''}
                        onClick={(e) => e.stopPropagation()}
                        onChange={(e) => actualizarCampo(p.id, 'latitud', Number(e.target.value))}
                        sx={{ flex: 1 }}
                      />
                      <TextField
                        size="small"
                        label="Longitud"
                        type="number"
                        inputProps={{ step: '0.0001' }}
                        value={p.longitud ?? ''}
                        onClick={(e) => e.stopPropagation()}
                        onChange={(e) => actualizarCampo(p.id, 'longitud', Number(e.target.value))}
                        sx={{ flex: 1 }}
                      />
                    </Box>
                    {p.latitud != null && p.longitud != null && (
                      <Link
                        href={urlGoogleMapsPunto(p.latitud, p.longitud)}
                        target="_blank"
                        rel="noopener noreferrer"
                        variant="caption"
                        onClick={(e) => e.stopPropagation()}
                      >
                        Ver en Google Maps
                      </Link>
                    )}
                    <Box display="flex" gap={1} mt={1}>
                      <Button
                        size="small"
                        variant="contained"
                        startIcon={saving ? <CircularProgress size={16} color="inherit" /> : <SaveIcon />}
                        disabled={saving}
                        onClick={(e) => {
                          e.stopPropagation();
                          guardarParada(p);
                        }}
                      >
                        Guardar
                      </Button>
                      <Button
                        size="small"
                        color="error"
                        variant="outlined"
                        startIcon={<DeleteIcon />}
                        disabled={saving || paradas.length <= 2}
                        onClick={(e) => {
                          e.stopPropagation();
                          borrarParada(p);
                        }}
                      >
                        Eliminar
                      </Button>
                    </Box>
                  </CardContent>
                </Card>
              ))
            )}
          </Grid>

          {paradas.length > 0 && (
            <Grid item xs={12}>
              <MapaRuta paradas={paradas} origen={origen} destino={destino} />
            </Grid>
          )}
        </Grid>
      )}
    </Box>
  );
}
