import {
  Box,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Typography,
  useMediaQuery,
  useTheme,
} from '@mui/material';
import type { ReactNode } from 'react';
import BusinessCenterIcon from '@mui/icons-material/BusinessCenter';
import DashboardIcon from '@mui/icons-material/Dashboard';
import DirectionsBusIcon from '@mui/icons-material/DirectionsBus';
import EventNoteIcon from '@mui/icons-material/EventNote';
import GroupsIcon from '@mui/icons-material/Groups';
import MapIcon from '@mui/icons-material/Map';
import MonetizationOnIcon from '@mui/icons-material/MonetizationOn';
import PeopleIcon from '@mui/icons-material/People';
import PieChartIcon from '@mui/icons-material/PieChart';
import StorefrontIcon from '@mui/icons-material/Storefront';

export type AdminSectionId =
  | 'plataforma'
  | 'perfil'
  | 'buses'
  | 'viajes'
  | 'operadores'
  | 'pasajeros'
  | 'ocupacion'
  | 'ingresos'
  | 'paradas';

export interface AdminNavItem {
  id: AdminSectionId;
  label: string;
  description: string;
  icon: ReactNode;
  globalOnly?: boolean;
  empresaOnly?: boolean;
}

export interface AdminNavGroup {
  title: string;
  items: AdminNavItem[];
}

const ICONS = {
  plataforma: <DashboardIcon fontSize="small" />,
  perfil: <StorefrontIcon fontSize="small" />,
  buses: <DirectionsBusIcon fontSize="small" />,
  viajes: <EventNoteIcon fontSize="small" />,
  operadores: <GroupsIcon fontSize="small" />,
  pasajeros: <PeopleIcon fontSize="small" />,
  ocupacion: <PieChartIcon fontSize="small" />,
  ingresos: <MonetizationOnIcon fontSize="small" />,
  paradas: <MapIcon fontSize="small" />,
};

export function buildAdminNav(esGlobal: boolean): AdminNavGroup[] {
  const groups: AdminNavGroup[] = [];

  if (esGlobal) {
    groups.push({
      title: 'Plataforma',
      items: [
        {
          id: 'plataforma',
          label: 'Cooperativas',
          description: 'Alta, métricas globales y accesos por tenant.',
          icon: ICONS.plataforma,
          globalOnly: true,
        },
      ],
    });
  }

  groups.push({
    title: esGlobal ? 'Cooperativa seleccionada' : 'Mi cooperativa',
    items: [
      {
        id: 'perfil',
        label: esGlobal ? 'Perfil y datos' : 'Datos de empresa',
        description: 'Nombre, contacto, tarifas de equipaje y logo.',
        icon: ICONS.perfil,
      },
    ],
  });

  groups.push({
    title: 'Operación diaria',
    items: [
      {
        id: 'buses',
        label: 'Flota de buses',
        description: 'Registro de unidades, sede terminal y asientos.',
        icon: ICONS.buses,
      },
      {
        id: 'viajes',
        label: 'Viajes programados',
        description: 'Salidas Bluefields ↔ Managua por fecha y terminal.',
        icon: ICONS.viajes,
      },
    ],
  });

  if (!esGlobal) {
    groups.push({
      title: 'Personal',
      items: [
        {
          id: 'operadores',
          label: 'Operadores',
          description: 'Cajeros y administradores con terminal asignada.',
          icon: ICONS.operadores,
          empresaOnly: true,
        },
        {
          id: 'pasajeros',
          label: 'Pasajeros',
          description: 'Manifiesto y consulta de boletos vendidos.',
          icon: ICONS.pasajeros,
          empresaOnly: true,
        },
      ],
    });
  }

  groups.push({
    title: 'Reportes',
    items: [
      {
        id: 'ocupacion',
        label: 'Ocupación',
        description: 'Cupos vendidos, reservados y libres por viaje.',
        icon: ICONS.ocupacion,
      },
      {
        id: 'ingresos',
        label: 'Ingresos',
        description: 'Ventas completadas, desglose por cajero y terminal.',
        icon: ICONS.ingresos,
      },
    ],
  });

  groups.push({
    title: 'Configuración',
    items: [
      {
        id: 'paradas',
        label: 'Ruta y paradas',
        description: 'Paradas del corredor interurbano en el mapa.',
        icon: ICONS.paradas,
      },
    ],
  });

  return groups;
}

export function findNavItem(
  groups: AdminNavGroup[],
  sectionId: AdminSectionId
): AdminNavItem | undefined {
  for (const g of groups) {
    const found = g.items.find((i) => i.id === sectionId);
    if (found) return found;
  }
  return undefined;
}

interface Props {
  section: AdminSectionId;
  onSectionChange: (id: AdminSectionId) => void;
  esGlobal: boolean;
  variant?: 'inline' | 'sidebar';
}

export function AdminNav({ section, onSectionChange, esGlobal, variant = 'inline' }: Props) {
  const theme = useTheme();
  const mobile = useMediaQuery(theme.breakpoints.down('md'));
  const groups = buildAdminNav(esGlobal);
  const isSidebar = variant === 'sidebar';

  return (
    <Box
      component="nav"
      aria-label="Secciones de administración"
      className={isSidebar ? 'admin-nav admin-nav--sidebar' : 'admin-nav admin-nav--inline'}
      sx={
        isSidebar
          ? undefined
          : {
              bgcolor: 'background.paper',
              border: 1,
              borderColor: 'divider',
              borderRadius: 3,
              overflow: 'hidden',
              ...(mobile && {
                display: 'flex',
                overflowX: 'auto',
                borderRadius: 2,
                '& .nav-group': { minWidth: 'max-content' },
              }),
            }
      }
    >
      {groups.map((group) => (
        <Box key={group.title} className="nav-group" sx={{ px: mobile && !isSidebar ? 1 : 0, py: mobile && !isSidebar ? 1 : 0 }}>
          {(!mobile || isSidebar) && (
            <Typography
              variant="overline"
              className="admin-nav__group-title"
              sx={
                isSidebar
                  ? { display: 'block', px: 2, pt: 1.5, pb: 0.5, opacity: 0.55, fontWeight: 700, letterSpacing: 1 }
                  : {
                      display: 'block',
                      px: 2,
                      pt: 2,
                      pb: 0.5,
                      color: 'text.secondary',
                      fontWeight: 700,
                      letterSpacing: 0.8,
                    }
              }
            >
              {group.title}
            </Typography>
          )}
          <List dense disablePadding sx={{ pb: isSidebar ? 0.5 : mobile ? 0 : 1 }}>
            {group.items.map((item) => {
              const active = section === item.id;
              return (
                <ListItemButton
                  key={item.id}
                  selected={active}
                  onClick={() => onSectionChange(item.id)}
                  className={active ? 'admin-nav__item admin-nav__item--active' : 'admin-nav__item'}
                  sx={
                    isSidebar
                      ? {
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
                        }
                      : {
                          mx: mobile ? 0.5 : 1,
                          mb: 0.25,
                          borderRadius: 2,
                          minWidth: mobile ? 140 : undefined,
                          '&.Mui-selected': {
                            bgcolor: 'primary.main',
                            color: 'primary.contrastText',
                            '& .MuiListItemIcon-root': { color: 'inherit' },
                            '&:hover': { bgcolor: 'primary.dark' },
                          },
                        }
                  }
                >
                  <ListItemIcon sx={{ minWidth: 36, color: active && !isSidebar ? 'inherit' : isSidebar ? 'rgba(255,255,255,0.7)' : 'primary.main' }}>
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
      ))}
    </Box>
  );
}

export function AdminSectionIntro({
  title,
  description,
}: {
  title: string;
  description: string;
}) {
  return (
    <Box className="admin-section-intro">
      <BusinessCenterIcon color="primary" sx={{ mt: 0.25 }} />
      <Box>
        <Typography variant="subtitle1" fontWeight={700}>
          {title}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          {description}
        </Typography>
      </Box>
    </Box>
  );
}
