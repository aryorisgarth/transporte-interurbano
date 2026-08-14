import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import {
  Alert,
  Box,
  Button,
  CircularProgress,
  Typography,
} from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import InfoOutlinedIcon from '@mui/icons-material/InfoOutlined';
import { detalleViaje, tarifaReferenciaUsd, type DetalleViaje } from '@/shared/api';
import { MapaRuta, EmpresaAvatar } from '@/shared/maps/MapaRuta';
import { SeatMap } from '@/shared/maps/SeatMap';
import { PageHeader } from '@/shared/ui/PageHeader';
import { SectionCard } from '@/shared/ui/SectionCard';
import { formatearCordobas, formatearHora } from '@/shared/utils/formato';

export default function DetalleViajePage() {
  const { id } = useParams<{ id: string }>();
  const [detalle, setDetalle] = useState<DetalleViaje | null>(null);
  const [usd, setUsd] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;

    async function cargar() {
      setLoading(true);
      setError(null);
      try {
        const data = await detalleViaje(Number(id));
        setDetalle(data);
        try {
          const ref = await tarifaReferenciaUsd(data.tarifa);
          setUsd(`~ USD ${Number(ref.equivalenteUsd).toFixed(2)} (referencia)`);
        } catch {
          setUsd(null);
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Error al cargar viaje');
      } finally {
        setLoading(false);
      }
    }

    cargar();
  }, [id]);

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" py={6}>
        <CircularProgress />
      </Box>
    );
  }

  if (error || !detalle) {
    return (
      <Box>
        <Button component={Link} to="/consulta" startIcon={<ArrowBackIcon />} sx={{ mb: 2 }}>
          Volver a consulta
        </Button>
        <Alert severity="error">{error ?? 'Viaje no encontrado'}</Alert>
      </Box>
    );
  }

  const subtitle = [
    detalle.empresaNombre,
    detalle.busNumeroInterno ? `Bus ${detalle.busNumeroInterno}` : null,
    `${detalle.fecha} · ${formatearHora(detalle.horaSalida)}`,
  ]
    .filter(Boolean)
    .join(' · ');

  return (
    <Box>
      <Button component={Link} to="/consulta" startIcon={<ArrowBackIcon />} sx={{ mb: 2 }}>
        Volver a consulta
      </Button>

      <PageHeader
        title={`${detalle.origen} → ${detalle.destino}`}
        subtitle={subtitle}
        actions={
          <Box sx={{ textAlign: { xs: 'left', sm: 'right' } }}>
            <Typography fontWeight={700} sx={{ color: '#fff' }}>
              {formatearCordobas(detalle.tarifa)}
            </Typography>
            {usd && (
              <Typography variant="caption" sx={{ opacity: 0.85, color: '#fff' }}>
                {usd}
              </Typography>
            )}
          </Box>
        }
      />

      <Box display="flex" alignItems="center" gap={2} mb={2}>
        <EmpresaAvatar nombre={detalle.empresaNombre} logoUrl={detalle.empresaLogoUrl} size={48} />
        <Box>
          <Typography variant="body2" color="text.secondary">
            Equipaje extra: {formatearCordobas(detalle.tarifaEquipajeExtra)} por unidad
          </Typography>
          <Typography color="text.secondary">
            {detalle.asientosDisponibles} asiento(s) disponible(s)
          </Typography>
        </Box>
      </Box>

      <Alert severity="info" icon={<InfoOutlinedIcon />} sx={{ mb: 3 }}>
        Esta consulta es solo informativa. Para comprar, presente su cédula en la terminal de la
        empresa el día anterior o el mismo día del viaje. No se requiere cuenta de usuario.
      </Alert>

      {detalle.paradas && detalle.paradas.length > 0 && (
        <MapaRuta paradas={detalle.paradas} origen={detalle.origen} destino={detalle.destino} />
      )}

      <SectionCard title="Mapa de asientos" noPadding>
        <Box sx={{ p: 2, minHeight: 520 }}>
          <SeatMap
            asientos={detalle.asientos}
            seleccionados={[]}
            fillContainer
            busMarca="Yutong"
            busFotoUrl={detalle.busFotoUrl}
            busNumeroInterno={detalle.busNumeroInterno}
          />
        </Box>
      </SectionCard>
    </Box>
  );
}
