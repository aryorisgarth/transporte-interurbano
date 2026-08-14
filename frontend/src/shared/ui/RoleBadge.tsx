import { Chip } from '@mui/material';
import { ROLE_COLORS, ROLE_LABELS } from '@/shared/utils/rolesUi';

interface Props {
  role: string;
  size?: 'small' | 'medium';
  inverted?: boolean;
}

export function RoleBadge({ role, size = 'small', inverted = false }: Props) {
  const color = ROLE_COLORS[role] ?? 'default';
  return (
    <Chip
      size={size}
      label={ROLE_LABELS[role] ?? role}
      color={inverted ? 'default' : color}
      sx={
        inverted
          ? {
              bgcolor: 'rgba(255,255,255,0.2)',
              color: '#rrr',
              fontWeight: 600,
              backdropFilter: 'blur(4px)',
            }
          : { fontWeight: 600 }
      }
    />
  );
}
