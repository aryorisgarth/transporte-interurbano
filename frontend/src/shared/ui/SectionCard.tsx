import { Card, CardContent, Stack, Typography } from '@mui/material';
import type { ReactNode } from 'react';

interface Props {
  title?: string;
  subtitle?: string;
  children: ReactNode;
  noPadding?: boolean;
  actions?: ReactNode;
  className?: string;
}

export function SectionCard({ title, subtitle, children, noPadding, actions, className }: Props) {
  const hasHeader = title || subtitle || actions;

  return (
    <Card className={className} sx={{ height: '100%', overflow: 'hidden' }}>
      {hasHeader && (
        <CardContent
          sx={{
            py: 1.5,
            px: 2,
            '&:last-child': { pb: noPadding ? 1.5 : 1.5 },
            borderBottom: hasHeader ? 1 : 0,
            borderColor: 'divider',
            bgcolor: 'rgba(248, 250, 252, 0.6)',
          }}
        >
          <Stack direction="row" alignItems="flex-start" justifyContent="space-between" spacing={2}>
            <BoxHeader title={title} subtitle={subtitle} />
            {actions && <Stack direction="row" spacing={1} flexShrink={0}>{actions}</Stack>}
          </Stack>
        </CardContent>
      )}
      {noPadding ? children : <CardContent sx={{ p: 2 }}>{children}</CardContent>}
    </Card>
  );
}

function BoxHeader({ title, subtitle }: { title?: string; subtitle?: string }) {
  if (!title && !subtitle) return null;
  return (
    <div>
      {title && (
        <Typography variant="subtitle1" fontWeight={700} sx={{ lineHeight: 1.3 }}>
          {title}
        </Typography>
      )}
      {subtitle && (
        <Typography variant="caption" color="text.secondary" sx={{ mt: 0.25, display: 'block' }}>
          {subtitle}
        </Typography>
      )}
    </div>
  );
}
