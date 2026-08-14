import { Avatar, Box, Button, Card, CardContent, Link, List, ListItem, ListItemText, Typography } from '@mui/material';
import MapIcon from '@mui/icons-material/Map';
import PlaceIcon from '@mui/icons-material/Place';
import { formatearHoraNicaragua } from '@/shared/utils/formato';
import { MapaParadasLeaflet, urlGoogleMapsCoordenadas } from '@/shared/maps/MapaParadasLeaflet';

export interface ParadaRuta {
  id: number;
  nombre: string;
  orden: number;
  horaEstimada: string | null;
  latitud: number | null;
  longitud: number | null;
}

interface Props {
  paradas: ParadaRuta[];
  origen?: string;
  destino?: string;
}

export function ParadasTimeline({ paradas }: { paradas: ParadaRuta[] }) {
  if (paradas.length === 0) return null;

  return (
    <List dense disablePadding>
      {paradas.map((p, i) => (
        <ListItem key={p.id} sx={{ pl: 0 }}>
          <PlaceIcon
            color={i === 0 ? 'primary' : i === paradas.length - 1 ? 'error' : 'action'}
            sx={{ mr: 1.5, fontSize: 20 }}
          />
          <ListItemText
            primary={`${p.orden}. ${p.nombre}`}
            secondary={
              <>
                {p.latitud != null && p.longitud != null && (
                  <span>
                    GPS: {p.latitud.toFixed(4)}, {p.longitud.toFixed(4)}
                    {p.horaEstimada ? ' · ' : ''}
                  </span>
                )}
                {p.horaEstimada
                  ? `Llegada estimada: ${formatearHoraNicaragua(p.horaEstimada + ':00')}`
                  : undefined}
              </>
            }
          />
        </ListItem>
      ))}
    </List>
  );
}

export function MapaRuta({ paradas, origen, destino }: Props) {
  if (paradas.length === 0) return null;

  const mapsUrl = urlGoogleMapsCoordenadas(paradas);

  return (
    <Card sx={{ mb: 3 }}>
      <CardContent>
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={2} flexWrap="wrap" gap={1}>
          <Typography variant="h6">
            Ruta {origen && destino ? `${origen} → ${destino}` : 'en mapa'}
          </Typography>
          <Button
            size="small"
            startIcon={<MapIcon />}
            component={Link}
            href={mapsUrl}
            target="_blank"
            rel="noopener noreferrer"
          >
            Abrir ruta en Google Maps
          </Button>
        </Box>

        <ParadasTimeline paradas={paradas} />

        <Box sx={{ mt: 2 }}>
          <MapaParadasLeaflet paradas={paradas} height={360} />
        </Box>

        <Typography variant="caption" color="text.secondary" display="block" sx={{ mt: 1 }}>
          Marcadores: salida, paradas intermedias y llegada con coordenadas GPS reales.
          Horarios estimados según salida programada. GPS del bus en vivo — fase futura.
        </Typography>
      </CardContent>
    </Card>
  );
}

export function EmpresaAvatar({ nombre, logoUrl, size = 40 }: { nombre: string; logoUrl?: string | null; size?: number }) {
  return (
    <Avatar src={logoUrl ?? undefined} alt={nombre} sx={{ width: size, height: size }}>
      {nombre.charAt(0)}
    </Avatar>
  );
}
