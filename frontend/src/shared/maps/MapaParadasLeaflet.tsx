import { useEffect, useRef } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Box, Typography } from '@mui/material';
import type { ParadaRuta } from '@/shared/api';

const iconoParada = new L.Icon({
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
});

/** Centro aproximado corredor Bluefields–Managua */
const CENTRO_NICARAGUA: L.LatLngExpression = [12.4, -85.0];

interface Props {
  paradas: ParadaRuta[];
  height?: number;
  onMapClick?: (lat: number, lng: number) => void;
  onMarkerDrag?: (id: number, lat: number, lng: number) => void;
  selectedId?: number | null;
  editable?: boolean;
}

function paradasConCoordenadas(paradas: ParadaRuta[]) {
  return paradas.filter((p) => p.latitud != null && p.longitud != null);
}

export function MapaParadasLeaflet({
  paradas,
  height = 360,
  onMapClick,
  onMarkerDrag,
  selectedId,
  editable = false,
}: Props) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const layerRef = useRef<L.LayerGroup | null>(null);
  const onMapClickRef = useRef(onMapClick);
  const onMarkerDragRef = useRef(onMarkerDrag);

  onMapClickRef.current = onMapClick;
  onMarkerDragRef.current = onMarkerDrag;

  useEffect(() => {
    if (!containerRef.current) return;

    if (!mapRef.current) {
      mapRef.current = L.map(containerRef.current, { scrollWheelZoom: true });
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap',
        maxZoom: 18,
      }).addTo(mapRef.current);

      mapRef.current.on('click', (e) => {
        onMapClickRef.current?.(e.latlng.lat, e.latlng.lng);
      });

      layerRef.current = L.layerGroup().addTo(mapRef.current);
    }

    layerRef.current!.clearLayers();

    const puntos = paradasConCoordenadas(paradas);
    const latlngs: L.LatLngExpression[] = [];

    puntos.forEach((p, i) => {
      const lat = p.latitud!;
      const lng = p.longitud!;
      latlngs.push([lat, lng]);

      const esInicio = i === 0;
      const esFin = i === puntos.length - 1;
      const esSeleccionada = selectedId === p.id;
      const draggable = editable && !!onMarkerDragRef.current;

      const marker = L.marker([lat, lng], {
        icon: iconoParada,
        draggable,
        opacity: selectedId != null && !esSeleccionada ? 0.5 : 1,
      }).bindPopup(
        `<strong>${p.orden}. ${p.nombre}</strong><br/>${lat.toFixed(5)}, ${lng.toFixed(5)}` +
          (p.horaEstimada ? `<br/>~ ${p.horaEstimada}` : '') +
          (esInicio ? '<br/><em>Salida</em>' : esFin ? '<br/><em>Llegada</em>' : '') +
          (draggable ? '<br/><em>Arrastre para mover</em>' : '')
      );

      if (draggable) {
        marker.on('dragend', () => {
          const pos = marker.getLatLng();
          onMarkerDragRef.current?.(p.id, pos.lat, pos.lng);
        });
      }

      layerRef.current!.addLayer(marker);
    });

    if (latlngs.length >= 2) {
      layerRef.current!.addLayer(
        L.polyline(latlngs, {
          color: '#1565c0',
          weight: 4,
          opacity: 0.85,
        })
      );
    }

    if (latlngs.length > 0) {
      mapRef.current.fitBounds(L.latLngBounds(latlngs), { padding: [48, 48] });
    } else {
      mapRef.current.setView(CENTRO_NICARAGUA, 7);
    }

    setTimeout(() => mapRef.current?.invalidateSize(), 100);
  }, [paradas, selectedId, editable]);

  useEffect(() => {
    return () => {
      mapRef.current?.remove();
      mapRef.current = null;
      layerRef.current = null;
    };
  }, []);

  return (
    <Box
      ref={containerRef}
      sx={{
        height,
        width: '100%',
        borderRadius: 1,
        overflow: 'hidden',
        border: 2,
        borderColor: editable ? 'primary.light' : 'divider',
        cursor: editable && onMapClick ? 'crosshair' : 'default',
        '& .leaflet-container': { height: '100%', width: '100%', zIndex: 0 },
      }}
    />
  );
}

export function urlGoogleMapsCoordenadas(paradas: ParadaRuta[]): string {
  const puntos = paradasConCoordenadas(paradas);
  if (puntos.length === 0) return 'https://www.google.com/maps';
  const segmentos = puntos.map((p) => `${p.latitud},${p.longitud}`);
  return `https://www.google.com/maps/dir/${segmentos.join('/')}`;
}

export function urlGoogleMapsPunto(lat: number, lng: number): string {
  return `https://www.google.com/maps?q=${lat},${lng}`;
}
