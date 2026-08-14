import { Navigate, Route, Routes, useParams } from 'react-router-dom';
import { Layout } from '@/shared/layout/Layout';
import { ProtectedRoute } from '@/features/auth';
import { LandingPage, ConsultaPublica, DetalleViajePage } from '@/features/consulta';
import AccesoPersonal from '@/features/auth/pages/AccesoPersonal';
import LoginPersonal from '@/features/auth/pages/LoginPersonal';
import { CajeroDashboard, PanelCajero } from '@/features/cajero';
import CajeroPasajeros from '@/features/cajero/pages/CajeroPasajeros';
import { CajeroLayout } from '@/features/cajero/layout/CajeroLayout';
import { AdminDashboard } from '@/features/admin';
import NotFound from '@/shared/pages/NotFound';
import { ROLES } from '@/shared/utils/jwt';

function RedirectViajeLegacy() {
  const { id } = useParams<{ id: string }>();
  return <Navigate to={`/consulta/viaje/${id}`} replace />;
}

export default function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route path="/" element={<LandingPage />} />
        <Route path="/consulta" element={<ConsultaPublica />} />
        <Route path="/consulta/viaje/:id" element={<DetalleViajePage />} />
        <Route path="/viaje/:id" element={<RedirectViajeLegacy />} />
        <Route path="/acceso" element={<AccesoPersonal />} />
        <Route path="/acceso/login" element={<LoginPersonal />} />
        <Route
          path="/cajero"
          element={
            <ProtectedRoute roles={[ROLES.CAJERO]}>
              <CajeroLayout />
            </ProtectedRoute>
          }
        >
          <Route index element={<CajeroDashboard />} />
          <Route path="pasajeros" element={<CajeroPasajeros />} />
          <Route path="venta/:id" element={<PanelCajero />} />
        </Route>
        <Route
          path="/admin"
          element={
            <ProtectedRoute roles={[ROLES.ADMIN_EMPRESA, ROLES.ADMIN_GENERAL]}>
              <AdminDashboard />
            </ProtectedRoute>
          }
        />
        <Route path="*" element={<NotFound />} />
      </Route>
    </Routes>
  );
}
