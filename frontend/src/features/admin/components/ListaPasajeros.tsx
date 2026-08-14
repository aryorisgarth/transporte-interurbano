import { useEffect, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  CircularProgress,
  MenuItem,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from '@mui/material';
import DownloadIcon from '@mui/icons-material/Download';
import PrintIcon from '@mui/icons-material/Print';
import {
  busesMiEmpresa,
  busesPorEmpresa,
  manifiestoPasajeros,
  viajesMiEmpresa,
  viajesPorEmpresa,
  type Bus,
  type ManifiestoPasajero,
  type ViajeOperador,
} from '@/shared/api';
import { exportarCsv, imprimirElemento } from '@/shared/utils/exportCsv';
import { fechaHoyLocal, formatearHora } from '@/shared/utils/formato';

interface Props {
  token: string;
  empresaId: number;
  esGlobal?: boolean;
}

export function ListaPasajeros({ token, empresaId, esGlobal = false }: Props) {
  const [fecha, setFecha] = useState(fechaHoyLocal());
  const [viajeId, setViajeId] = useState<number | ''>('');
  const [busId, setBusId] = useState<number | ''>('');
  const [viajes, setViajes] = useState<ViajeOperador[]>([]);
  const [buses, setBuses] = useState<Bus[]>([]);
  const [pasajeros, setPasajeros] = useState<ManifiestoPasajero[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function cargarFiltros() {
      try {
        const [v, b] = await Promise.all([
          esGlobal
            ? viajesPorEmpresa(token, empresaId, fecha)
            : viajesMiEmpresa(token, fecha),
          esGlobal ? busesPorEmpresa(token, empresaId) : busesMiEmpresa(token),
        ]);
        setViajes(v);
        setBuses(b);
      } catch {
        setViajes([]);
        setBuses([]);
      }
    }
    cargarFiltros();
  }, [token, empresaId, fecha, esGlobal]);

  useEffect(() => {
    async function cargar() {
      setLoading(true);
      setError(null);
      try {
        const data = await manifiestoPasajeros(token, {
          fecha,
          empresaId: esGlobal ? empresaId : undefined,
          viajeId: viajeId !== '' ? viajeId : undefined,
          busId: busId !== '' ? busId : undefined,
        });
        setPasajeros(data);
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Error al cargar pasajeros');
        setPasajeros([]);
      } finally {
        setLoading(false);
      }
    }
    cargar();
  }, [token, empresaId, fecha, viajeId, busId, esGlobal]);

  function handleExportCsv() {
    exportarCsv(
      `manifiesto-${fecha}.csv`,
      [
        'Fecha',
        'Hora',
        'Ruta',
        'Bus',
        'Placa',
        'Asiento',
        'Pasajero',
        'Cédula',
        'Teléfono',
        'Código venta',
        'Operador',
      ],
      pasajeros.map((p) => [
        p.fechaViaje,
        formatearHora(p.horaSalida),
        `${p.origen} → ${p.destino}`,
        p.busNumeroInterno,
        p.busPlaca,
        p.numeroAsiento,
        p.pasajeroNombre,
        p.pasajeroCedula,
        p.pasajeroTelefono ?? '',
        p.codigoVenta,
        p.operadorNombre,
      ])
    );
  }

  function handlePrint() {
    imprimirElemento('manifiesto-print', `Manifiesto de pasajeros — ${fecha}`);
  }

  return (
    <Box>
      <Box display="flex" gap={2} flexWrap="wrap" alignItems="center" sx={{ mb: 3 }}>
        <TextField
          type="date"
          label="Fecha"
          size="small"
          value={fecha}
          onChange={(e) => {
            setFecha(e.target.value);
            setViajeId('');
          }}
          InputLabelProps={{ shrink: true }}
        />
        <TextField
          select
          label="Viaje"
          size="small"
          sx={{ minWidth: 220 }}
          value={viajeId}
          onChange={(e) => setViajeId(e.target.value === '' ? '' : Number(e.target.value))}
        >
          <MenuItem value="">Todos</MenuItem>
          {viajes.map((v) => (
            <MenuItem key={v.id} value={v.id}>
              {formatearHora(String(v.horaSalida))} · Bus {v.busNumeroInterno}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          select
          label="Bus"
          size="small"
          sx={{ minWidth: 160 }}
          value={busId}
          onChange={(e) => setBusId(e.target.value === '' ? '' : Number(e.target.value))}
        >
          <MenuItem value="">Todos</MenuItem>
          {buses.map((b) => (
            <MenuItem key={b.id} value={b.id}>
              {b.numeroInterno} ({b.placa})
            </MenuItem>
          ))}
        </TextField>
        <Box flexGrow={1} />
        <Button
          variant="outlined"
          startIcon={<DownloadIcon />}
          onClick={handleExportCsv}
          disabled={pasajeros.length === 0}
        >
          Excel (CSV)
        </Button>
        <Button
          variant="outlined"
          startIcon={<PrintIcon />}
          onClick={handlePrint}
          disabled={pasajeros.length === 0}
        >
          PDF / Imprimir
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Pasajeros ({pasajeros.length})
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Una fila por boleto/asiento. Misma compra con varios asientos repite nombre si es un solo
            comprador.
          </Typography>

          {loading ? (
            <Box display="flex" justifyContent="center" py={4}>
              <CircularProgress />
            </Box>
          ) : pasajeros.length === 0 ? (
            <Alert severity="info">No hay pasajeros registrados para los filtros seleccionados.</Alert>
          ) : (
            <>
              <TableContainer component={Paper} variant="outlined" id="manifiesto-print">
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Hora</TableCell>
                      <TableCell>Ruta</TableCell>
                      <TableCell>Bus</TableCell>
                      <TableCell>Asiento</TableCell>
                      <TableCell>Pasajero</TableCell>
                      <TableCell>Cédula</TableCell>
                      <TableCell>Menor</TableCell>
                      <TableCell>Teléfono</TableCell>
                      <TableCell>Estado</TableCell>
                      <TableCell>Venta</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {pasajeros.map((p) => (
                      <TableRow key={p.boletoId}>
                        <TableCell>{formatearHora(p.horaSalida)}</TableCell>
                        <TableCell>
                          {p.origen} → {p.destino}
                        </TableCell>
                        <TableCell>
                          {p.busNumeroInterno} ({p.busPlaca})
                        </TableCell>
                        <TableCell>{p.numeroAsiento}</TableCell>
                        <TableCell>{p.pasajeroNombre}</TableCell>
                        <TableCell>{p.pasajeroCedula}</TableCell>
                        <TableCell>{p.esMenor ? 'Sí' : '—'}</TableCell>
                        <TableCell>{p.pasajeroTelefono ?? '—'}</TableCell>
                        <TableCell>
                          {p.estadoBoleto === 'RESERVA_EXCEPCIONAL' ? 'Reserva' : 'Vendido'}
                        </TableCell>
                        <TableCell>{p.codigoVenta}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </>
          )}
        </CardContent>
      </Card>
    </Box>
  );
}
