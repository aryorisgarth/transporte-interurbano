import { Box, Typography } from '@mui/material';
import type { ReactNode } from 'react';
import { SectionCard } from '@/shared/ui/SectionCard';

interface Props {
  label: string;
  value: string | number;
  icon: ReactNode;
  accent?: string;
  hint?: string;
  compact?: boolean;
}

export function StatCard({ label, value, icon, accent = '#0f766e', hint, compact }: Props) {
  const iconSize = compact ? 36 : 44;
  const padding = compact ? 1.75 : 2.5;

  return (
    <SectionCard noPadding className={compact ? 'stat-card--compact' : undefined}>
      <Box sx={{ p: padding, display: 'flex', gap: compact ? 1.25 : 2, alignItems: 'center', height: '100%' }}>
        <Box
          sx={{
            width: iconSize,
            height: iconSize,
            borderRadius: 2,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            bgcolor: `${accent}14`,
            color: accent,
            flexShrink: 0,
            '& svg': { fontSize: compact ? 20 : 24 },
          }}
        >
          {icon}
        </Box>
        <Box sx={{ minWidth: 0 }}>
          <Typography
            variant="caption"
            color="text.secondary"
            fontWeight={600}
            sx={{ textTransform: 'uppercase', letterSpacing: 0.4, fontSize: compact ? '0.65rem' : '0.7rem' }}
          >
            {label}
          </Typography>
          <Typography variant={compact ? 'h6' : 'h5'} fontWeight={800} sx={{ lineHeight: 1.15 }}>
            {value}
          </Typography>
          {hint && (
            <Typography variant="caption" color="text.secondary" display="block" sx={{ mt: 0.25 }}>
              {hint}
            </Typography>
          )}
        </Box>
      </Box>
    </SectionCard>
  );
}
