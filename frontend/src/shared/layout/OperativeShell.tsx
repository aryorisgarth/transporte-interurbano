import {
  Avatar,
  Box,
  Drawer,
  IconButton,
  Stack,
  Typography,
  useMediaQuery,
  useTheme,
} from '@mui/material';
import MenuIcon from '@mui/icons-material/Menu';
import DirectionsBusFilledIcon from '@mui/icons-material/DirectionsBusFilled';
import LogoutIcon from '@mui/icons-material/Logout';
import type { ReactNode } from 'react';
import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '@/features/auth/AuthContext';
import { RoleBadge } from '@/shared/ui/RoleBadge';

export interface OperativeShellLink {
  label: string;
  to: string;
}

interface Props {
  brandSubtitle: string;
  role: string;
  title: string;
  description?: string;
  nav: ReactNode;
  sidebarFooter?: ReactNode;
  topBarExtra?: ReactNode;
  footerLinks?: OperativeShellLink[];
  contentClassName?: string;
  children: ReactNode;
}

export function OperativeShell({
  brandSubtitle,
  role,
  title,
  description,
  nav,
  sidebarFooter,
  topBarExtra,
  footerLinks = [{ label: 'Consulta pública', to: '/consulta' }],
  contentClassName,
  children,
}: Props) {
  const theme = useTheme();
  const mobile = useMediaQuery(theme.breakpoints.down('md'));
  const [drawerOpen, setDrawerOpen] = useState(false);
  const { username, logout } = useAuth();

  const sidebar = (
    <Box className="admin-sidebar__inner">
      <Box className="admin-sidebar__brand">
        <DirectionsBusFilledIcon sx={{ fontSize: 28 }} />
        <Box>
          <Typography variant="subtitle1" fontWeight={800} lineHeight={1.2}>
            Transporte B–M
          </Typography>
          <Typography variant="caption" sx={{ opacity: 0.75 }}>
            {brandSubtitle}
          </Typography>
        </Box>
      </Box>

      <Box className="admin-sidebar__nav">{nav}</Box>

      {sidebarFooter && <Box className="admin-sidebar__extra">{sidebarFooter}</Box>}

      <Box className="admin-sidebar__user">
        <Stack direction="row" spacing={1.5} alignItems="center">
          <Avatar sx={{ width: 36, height: 36, bgcolor: 'rgba(255,255,255,0.2)', fontSize: '0.875rem' }}>
            {(username ?? 'U')[0].toUpperCase()}
          </Avatar>
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Typography variant="body2" fontWeight={700} noWrap>
              {username}
            </Typography>
            <RoleBadge role={role} inverted />
          </Box>
        </Stack>
        <Stack direction="row" spacing={1.5} flexWrap="wrap" useFlexGap sx={{ mt: 1.5 }}>
          {footerLinks.map((link) => (
            <Typography
              key={link.to}
              component={Link}
              to={link.to}
              variant="caption"
              sx={{ color: 'rgba(255,255,255,0.7)', textDecoration: 'none', '&:hover': { color: '#fff' } }}
            >
              {link.label}
            </Typography>
          ))}
          <Typography component="button" variant="caption" onClick={logout} className="admin-sidebar__logout">
            <LogoutIcon sx={{ fontSize: 14, mr: 0.25, verticalAlign: 'middle' }} />
            Salir
          </Typography>
        </Stack>
      </Box>
    </Box>
  );

  return (
    <Box className="admin-shell">
      {!mobile && <Box component="aside" className="admin-sidebar">{sidebar}</Box>}

      {mobile && (
        <Drawer
          open={drawerOpen}
          onClose={() => setDrawerOpen(false)}
          PaperProps={{ className: 'admin-sidebar admin-sidebar--drawer' }}
        >
          {sidebar}
        </Drawer>
      )}

      <Box component="main" className="admin-shell__main">
        <Box className="admin-topbar">
          <Stack direction="row" alignItems="center" spacing={1.5} sx={{ flex: 1, minWidth: 0 }}>
            {mobile && (
              <IconButton onClick={() => setDrawerOpen(true)} edge="start" aria-label="Menú">
                <MenuIcon />
              </IconButton>
            )}
            <Box sx={{ minWidth: 0 }}>
              <Typography variant="h5" fontWeight={800} noWrap>
                {title}
              </Typography>
              {description && (
                <Typography variant="body2" color="text.secondary" noWrap>
                  {description}
                </Typography>
              )}
            </Box>
          </Stack>
          {topBarExtra && <Box className="admin-topbar__actions">{topBarExtra}</Box>}
        </Box>

        <Box className={contentClassName ? `admin-shell__content ${contentClassName}` : 'admin-shell__content'}>
          {children}
        </Box>
      </Box>
    </Box>
  );
}
