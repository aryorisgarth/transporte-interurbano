import { Box, Chip, Stack, Typography } from '@mui/material';
import type { AsientoViaje } from '@/shared/api';
import { ETIQUETAS_ESTADO_ASIENTO } from '@/shared/utils/formato';
import { seatColors } from '@/shared/theme';
import { BusSeatDiagram } from '@/features/cajero/components/BusSeatDiagram';

interface Props {
  asientos: AsientoViaje[];
  seleccionados: number[];
  onToggle?: (viajeAsientoId: number) => void;
  modoSeleccion?: boolean;
  fillContainer?: boolean;
  busMarca?: string;
  busFotoUrl?: string | null;
  busNumeroInterno?: string | null;
  compact?: boolean;
}

export function SeatMap({
  asientos,
  seleccionados,
  onToggle,
  modoSeleccion = false,
  fillContainer = true,
  busMarca = 'Yutong',
  busFotoUrl,
  busNumeroInterno,
  compact = false,
}: Props) {
  if (asientos.length === 0) {
    return <Typography color="text.secondary">No hay asientos configurados para este viaje.</Typography>;
  }

  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        height: fillContainer ? '100%' : 'auto',
        minHeight: fillContainer ? 0 : undefined,
      }}
    >
      <Stack direction="row" spacing={1} sx={{ mb: 1.5, flexWrap: 'wrap', gap: 0.75, flexShrink: 0 }}>
        {Object.entries(seatColors).map(([estado, color]) => (
          <Chip
            key={estado}
            size="small"
            label={ETIQUETAS_ESTADO_ASIENTO[estado] ?? estado}
            sx={{ bgcolor: color, color: '#fff' }}
          />
        ))}
        {modoSeleccion && (
          <Chip size="small" label="Seleccionado" sx={{ bgcolor: '#1565c0', color: '#fff' }} />
        )}
      </Stack>

      <Box sx={{ flex: fillContainer ? 1 : undefined, minHeight: 0, width: '100%' }}>
        <BusSeatDiagram
          asientos={asientos}
          seleccionados={seleccionados}
          onToggle={onToggle}
          modoSeleccion={modoSeleccion}
          fillContainer={fillContainer}
          busMarca={busMarca}
          busFotoUrl={busFotoUrl}
          busNumeroInterno={busNumeroInterno}
          compact={compact}
        />
      </Box>
    </Box>
  );
}
