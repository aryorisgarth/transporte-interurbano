import { Navigate } from 'react-router-dom';

/** Redirige al formulario de login unificado. */
export default function AccesoPersonal() {
  return <Navigate to="/acceso/login" replace />;
}
