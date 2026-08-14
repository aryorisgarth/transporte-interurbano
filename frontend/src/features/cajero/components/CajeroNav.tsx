import { Box, List, ListItemButton, ListItemIcon, ListItemText, Typography } from '@mui/material';
import EventNoteIcon from '@mui/icons-material/EventNote';
import PeopleIcon from '@mui/icons-material/People';
import { Link, useLocation } from 'react-router-dom';

export type CajeroSectionId = 'viajes' | 'pasajeros' | 'venta';

const ITEMS = [
  {
    id: 'viajes' as const,
    label: 'Viajes del día',
    description: 'Salidas programadas y venta en mostrador.',
    to: '/cajero',
    icon: <EventNoteIcon fontSize="small" />,
  },
  {
    id: 'pasajeros' as const,
    label: 'Lista de pasajeros',
    description: 'Manifiesto y boletos vendidos del día.',
    to: '/cajero/pasajeros',
    icon: <PeopleIcon fontSize="small" />,
  },
];

export function resolveCajeroSection(pathname: string): CajeroSectionId {
  if (pathname.startsWith('/cajero/venta')) return 'venta';
  if (pathname.startsWith('/cajero/pasajeros')) return 'pasajeros';
  return 'viajes';
}

export function cajeroSectionMeta(section: CajeroSectionId) {
  if (section === 'venta') {
    return {
      title: 'Registrar venta',
      description: 'Seleccione asientos, datos del comprador y confirme.',
    };
  }
  const item = ITEMS.find((i) => i.id === section);
  return {
    title: item?.label ?? 'Panel cajero',
    description: item?.description ?? 'Venta en terminal y manifiesto.',
  };
}

export function CajeroNav() {
  const { pathname } = useLocation();
  const section = resolveCajeroSection(pathname);

  return (
    <Box component="nav" aria-label="Secciones del cajero" className="admin-nav admin-nav--sidebar">
      <Typography
        variant="overline"
        className="admin-nav__group-title"
        sx={{ display: 'block', px: 2, pt: 1.5, pb: 0.5, opacity: 0.55, fontWeight: 700, letterSpacing: 1 }}
      >
        Terminal
      </Typography>
      <List dense disablePadding sx={{ pb: 0.5 }}>
        {ITEMS.map((item) => {
          const active = section === item.id || (item.id === 'viajes' && section === 'venta');
          return (
            <ListItemButton
              key={item.id}
              component={Link}
              to={item.to}
              selected={active}
              className={active ? 'admin-nav__item admin-nav__item--active' : 'admin-nav__item'}
              sx={{
                mx: 1,
                mb: 0.25,
                borderRadius: 2,
                color: 'inherit',
                '&.Mui-selected': {
                  bgcolor: 'rgba(255,255,255,0.14)',
                  color: '#fff',
                  boxShadow: 'inset 3px 0 0 #5eead4',
                  '& .MuiListItemIcon-root': { color: '#99f6e4' },
                },
                '&:hover': { bgcolor: 'rgba(255,255,255,0.08)' },
              }}
            >
              <ListItemIcon sx={{ minWidth: 36, color: active ? '#99f6e4' : 'rgba(255,255,255,0.7)' }}>
                {item.icon}
              </ListItemIcon>
              <ListItemText
                primary={item.label}
                primaryTypographyProps={{ fontWeight: active ? 700 : 600, fontSize: '0.875rem' }}
              />
            </ListItemButton>
          );
        })}
      </List>
    </Box>
  );
}
