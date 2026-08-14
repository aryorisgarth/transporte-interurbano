import { useOutletContext } from 'react-router-dom';
import { ListaPasajeros } from '@/features/admin/components/ListaPasajeros';
import { useAuth } from '@/features/auth/AuthContext';
import type { CajeroOutletContext } from '@/features/cajero/layout/CajeroLayout';

export default function CajeroPasajeros() {
  const { token } = useAuth();
  const { perfil } = useOutletContext<CajeroOutletContext>();

  if (!token || !perfil?.empresaId) {
    return null;
  }

  return <ListaPasajeros token={token} empresaId={perfil.empresaId} />;
}
