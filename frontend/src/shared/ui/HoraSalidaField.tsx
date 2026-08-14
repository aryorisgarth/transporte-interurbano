import {
  Box,
  FormControl,
  InputLabel,
  MenuItem,
  Select,
  Stack,
  ToggleButton,
  ToggleButtonGroup,
  Typography,
} from '@mui/material';
import type { HoraSalidaNicaragua, Meridiano } from '@/shared/utils/formato';

interface Props {
  value: HoraSalidaNicaragua;
  onChange: (value: HoraSalidaNicaragua) => void;
  label?: string;
  size?: 'small' | 'medium';
  disabled?: boolean;
}

const HORAS = Array.from({ length: 12 }, (_, i) => i + 1);
const MINUTOS = Array.from({ length: 60 }, (_, i) => String(i).padStart(2, '0'));

export function HoraSalidaField({
  value,
  onChange,
  label = 'Hora salida',
  size = 'medium',
  disabled = false,
}: Props) {
  return (
    <Box>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 0.75 }}>
        {label}
      </Typography>
      <Stack direction="row" spacing={1} alignItems="center" flexWrap="wrap" useFlexGap>
        <FormControl size={size} sx={{ minWidth: 76 }} disabled={disabled}>
          <InputLabel id="hora-salida-h">Hora</InputLabel>
          <Select
            labelId="hora-salida-h"
            label="Hora"
            value={value.hora}
            onChange={(e) => onChange({ ...value, hora: Number(e.target.value) })}
          >
            {HORAS.map((h) => (
              <MenuItem key={h} value={h}>
                {h}
              </MenuItem>
            ))}
          </Select>
        </FormControl>
        <Typography variant="h6" color="text.secondary">
          :
        </Typography>
        <FormControl size={size} sx={{ minWidth: 76 }} disabled={disabled}>
          <InputLabel id="hora-salida-m">Min</InputLabel>
          <Select
            labelId="hora-salida-m"
            label="Min"
            value={value.minuto}
            onChange={(e) => onChange({ ...value, minuto: e.target.value })}
          >
            {MINUTOS.map((m) => (
              <MenuItem key={m} value={m}>
                {m}
              </MenuItem>
            ))}
          </Select>
        </FormControl>
        <ToggleButtonGroup
          exclusive
          size={size}
          value={value.ampm}
          onChange={(_, meridiano: Meridiano | null) => {
            if (meridiano) onChange({ ...value, ampm: meridiano });
          }}
          disabled={disabled}
        >
          <ToggleButton value="AM" sx={{ px: 2 }}>
            AM
          </ToggleButton>
          <ToggleButton value="PM" sx={{ px: 2 }}>
            PM
          </ToggleButton>
        </ToggleButtonGroup>
      </Stack>
    </Box>
  );
}
