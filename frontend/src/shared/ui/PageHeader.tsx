import { Box, Stack, Typography } from '@mui/material';
import type { ReactNode } from 'react';

interface Props {
  title: string;
  subtitle?: string;
  badge?: ReactNode;
  actions?: ReactNode;
}

export function PageHeader({ title, subtitle, badge, actions }: Props) {
  return (
    <Box
      sx={{
        mb: 3,
        p: { xs: 2.5, md: 3 },
        borderRadius: 3,
        background: 'var(--app-gradient)',
        color: '#fff',
        boxShadow: '0 8px 32px rgba(12, 74, 110, 0.22)',
      }}
    >
      <Stack
        direction={{ xs: 'column', sm: 'row' }}
        justifyContent="space-between"
        alignItems={{ xs: 'flex-start', sm: 'center' }}
        spacing={2}
      >
        <Box>
          {badge && <Box sx={{ mb: 1 }}>{badge}</Box>}
          <Typography variant="h4" component="h1" fontWeight={800} sx={{ letterSpacing: -0.5 }}>
            {title}
          </Typography>
          {subtitle && (
            <Typography variant="body1" sx={{ mt: 0.75, opacity: 0.92, maxWidth: 720 }}>
              {subtitle}
            </Typography>
          )}
        </Box>
        {actions && <Box sx={{ flexShrink: 0 }}>{actions}</Box>}
      </Stack>
    </Box>
  );
}
