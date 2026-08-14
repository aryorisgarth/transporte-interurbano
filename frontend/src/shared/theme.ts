import { createTheme, alpha } from '@mui/material/styles';

const primary = {
  main: '#0f766e',
  light: '#14b8a6',
  dark: '#0c4a6e',
  contrastText: '#ffffff',
};

export const theme = createTheme({
  palette: {
    mode: 'light',
    primary,
    secondary: { main: '#0369a1', light: '#38bdf8', dark: '#075985' },
    background: { default: '#f0f4f8', paper: '#ffffff' },
    success: { main: '#15803d' },
    error: { main: '#b91c1c' },
    warning: { main: '#c2410c' },
    info: { main: '#7c3aed' },
    text: { primary: '#0f172a', secondary: '#475569' },
    divider: alpha('#0f172a', 0.08),
  },
  typography: {
    fontFamily: '"Plus Jakarta Sans", "Segoe UI", system-ui, sans-serif',
    h3: { fontWeight: 800, letterSpacing: -0.5 },
    h4: { fontWeight: 800, letterSpacing: -0.4 },
    h5: { fontWeight: 700 },
    h6: { fontWeight: 700 },
    button: { fontWeight: 700 },
  },
  shape: { borderRadius: 14 },
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        body: { scrollbarColor: `${alpha(primary.main, 0.4)} transparent` },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          borderRadius: 12,
          paddingLeft: 18,
          paddingRight: 18,
        },
        contained: { boxShadow: 'none', '&:hover': { boxShadow: '0 4px 14px rgba(15,118,110,0.25)' } },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          boxShadow: '0 4px 20px rgba(15, 23, 42, 0.06)',
          border: `1px solid ${alpha('#0f172a', 0.06)}`,
        },
      },
    },
    MuiTab: {
      styleOverrides: {
        root: { textTransform: 'none', fontWeight: 600, minHeight: 48 },
      },
    },
    MuiTabs: {
      styleOverrides: {
        indicator: { height: 3, borderRadius: 3 },
      },
    },
    MuiTextField: {
      defaultProps: { variant: 'outlined' },
    },
    MuiAppBar: {
      styleOverrides: {
        root: { boxShadow: '0 1px 0 rgba(15,23,42,0.08)' },
      },
    },
    MuiChip: {
      styleOverrides: { root: { fontWeight: 600 } },
    },
  },
});

export const seatColors: Record<string, string> = {
  DISPONIBLE: '#16a34a',
  VENDIDO: '#dc2626',
  CANCELADO: '#94a3b8',
  RESERVADO_EXCEPCIONAL: '#ea580c',
};

export const gradientHero = 'var(--app-gradient)';
