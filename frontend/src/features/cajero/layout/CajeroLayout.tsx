import { Box, CircularProgress, Typography } from '@mui/material';
import { Outlet, useLocation } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { CajeroNav, cajeroSectionMeta, resolveCajeroSection } from '@/features/cajero/components/CajeroNav';
import { OperativeShell } from '@/shared/layout/OperativeShell';
import { obtenerPerfil } from '@/shared/api';
import { useAuth } from '@/features/auth/AuthContext';
import { ROLES } from '@/shared/utils/jwt';
import { etiquetaTerminal, resolverTerminalCajero } from '@/shared/utils/terminalCajero';

export interface CajeroOutletContext {
  perfil: {
    nombreCompleto: string;
    empresaNombre: string | null;
    empresaId: number | null;
    sede: string | null;
  } | null;
}

export function CajeroLayout() {
  const { token, username } = useAuth();
  const location = useLocation();
  const section = resolveCajeroSection(location.pathname);
  const meta = cajeroSectionMeta(section);

  const [perfil, setPerfil] = useState<CajeroOutletContext['perfil']>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!token) return;
    setLoading(true);
    obtenerPerfil(token)
      .then((p) =>
        setPerfil({
          nombreCompleto: p.nombreCompleto,
          empresaNombre: p.empresaNombre,
          empresaId: p.empresaId,
          sede: p.sede,
        })
      )
      .finally(() => setLoading(false));
  }, [token]);

  if (loading && !perfil) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" height="100vh">
        <CircularProgress />
      </Box>
    );
  }

  const terminal = resolverTerminalCajero(perfil, username);

  const description =
    section === 'venta'
      ? meta.description
      : [perfil?.nombreCompleto, perfil?.empresaNombre, terminal ? `Terminal ${terminal}` : null]
          .filter(Boolean)
          .join(' · ') || meta.description;

  const sidebarFooter = (
    <Box sx={{ px: 1.5, py: 1 }}>
      <Typography variant="caption" sx={{ opacity: 0.6, fontWeight: 700, letterSpacing: 0.5 }}>
        TERMINAL ASIGNADA
      </Typography>
      <Box
        sx={{
          mt: 0.75,
          px: 1.25,
          py: 0.75,
          borderRadius: 1.5,
          border: '1px solid rgba(255,255,255,0.22)',
          bgcolor: terminal ? 'rgba(255,255,255,0.12)' : 'rgba(251,191,36,0.15)',
        }}
      >
        <Typography variant="body2" fontWeight={700} sx={{ color: '#fff', lineHeight: 1.3 }}>
          {etiquetaTerminal(terminal)}
        </Typography>
        {!terminal && (
          <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.75)', display: 'block', mt: 0.25 }}>
            Contacte al administrador de su cooperativa.
          </Typography>
        )}
      </Box>
    </Box>
  );

  return (
    <OperativeShell
      brandSubtitle="Terminal · venta en mostrador"
      role={ROLES.CAJERO}
      title={meta.title}
      description={description}
      nav={<CajeroNav />}
      sidebarFooter={sidebarFooter}
      contentClassName={section === 'venta' ? 'admin-shell__content--cajero-venta' : undefined}
    >
      <Outlet context={{ perfil }} />
    </OperativeShell>
  );
}
