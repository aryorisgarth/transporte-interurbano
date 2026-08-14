import { Alert, Box, Chip, MenuItem, TextField, Typography } from '@mui/material';
import BusinessIcon from '@mui/icons-material/Business';
import type { Empresa } from '@/shared/api';

interface Props {
  esGlobal: boolean;
  empresas: Empresa[];
  empresaId: number | '';
  empresaNombre: string;
  onChange: (id: number, nombre: string) => void;
  sectionHint?: string;
  compact?: boolean;
  sidebar?: boolean;
}

export function TenantSelector({
  esGlobal,
  empresas,
  empresaId,
  empresaNombre,
  onChange,
  sectionHint,
  compact,
  sidebar,
}: Props) {
  if (esGlobal) {
    if (empresas.length === 0) {
      return (
        <Alert severity="warning" sx={{ mb: sidebar ? 0 : 3, fontSize: sidebar ? '0.75rem' : undefined }}>
          Sin cooperativas. Cree una en Cooperativas.
        </Alert>
      );
    }

    if (sidebar) {
      return (
        <Box sx={{ px: 1.5, py: 1 }}>
          <Typography variant="caption" sx={{ opacity: 0.6, fontWeight: 700, letterSpacing: 0.5 }}>
            COOPERATIVA ACTIVA
          </Typography>
          <TextField
            select
            fullWidth
            size="small"
            value={empresaId}
            onChange={(e) => {
              const id = Number(e.target.value);
              const sel = empresas.find((em) => em.id === id);
              onChange(id, sel?.nombre ?? '');
            }}
            sx={{
              mt: 0.75,
              '& .MuiOutlinedInput-root': {
                bgcolor: 'rgba(255,255,255,0.08)',
                color: '#fff',
                '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' },
              },
              '& .MuiSelect-icon': { color: 'rgba(255,255,255,0.7)' },
            }}
          >
            {empresas.map((em) => (
              <MenuItem key={em.id} value={em.id}>
                {em.nombre}
              </MenuItem>
            ))}
          </TextField>
        </Box>
      );
    }

    if (compact) {
      return (
        <TextField
          select
          size="small"
          label="Cooperativa"
          value={empresaId}
          onChange={(e) => {
            const id = Number(e.target.value);
            const sel = empresas.find((em) => em.id === id);
            onChange(id, sel?.nombre ?? '');
          }}
          sx={{ minWidth: 220 }}
        >
          {empresas.map((em) => (
            <MenuItem key={em.id} value={em.id}>
              {em.nombre}
            </MenuItem>
          ))}
        </TextField>
      );
    }

    return (
      <Box
        sx={{
          mb: 3,
          p: 2,
          borderRadius: 2,
          bgcolor: 'background.paper',
          border: 1,
          borderColor: 'divider',
        }}
      >
        <Typography variant="subtitle2" fontWeight={700} gutterBottom>
          Cooperativa en contexto
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
          {sectionHint ??
            'Los módulos de flota, viajes y reportes aplican a la cooperativa que elija aquí.'}
        </Typography>
        <TextField
          select
          label="Cooperativa"
          value={empresaId}
          onChange={(e) => {
            const id = Number(e.target.value);
            const sel = empresas.find((em) => em.id === id);
            onChange(id, sel?.nombre ?? '');
          }}
          size="small"
          sx={{ minWidth: { xs: '100%', sm: 360 } }}
        >
          {empresas.map((em) => (
            <MenuItem key={em.id} value={em.id}>
              {em.nombre}
            </MenuItem>
          ))}
        </TextField>
      </Box>
    );
  }

  return (
    <Chip
      icon={<BusinessIcon />}
      label={empresaNombre || 'Mi cooperativa'}
      color="primary"
      variant="outlined"
      sx={{ fontSize: compact ? '0.85rem' : '0.95rem', ...(compact ? {} : { mb: 3, py: 2.5, px: 0.5 }) }}
    />
  );
}
