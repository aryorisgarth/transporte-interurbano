import { api } from './client';
import type { DetalleViaje, ViajeOperador } from './types';

export function detalleViajeOperador(viajeId: number, token: string) {
  return api.get<DetalleViaje>(`/api/viajes/${viajeId}/detalle-operador`, token);
}

export function viajesPorEmpresa(token: string, empresaId: number, fecha: string, origen?: string) {
  const q = new URLSearchParams({ empresaId: String(empresaId), fecha });
  if (origen) q.set('origen', origen);
  return api.get<ViajeOperador[]>(`/api/viajes?${q}`, token);
}

export function viajesMiEmpresa(token: string, fecha: string, origen?: string) {
  const q = new URLSearchParams({ fecha });
  if (origen) q.set('origen', origen);
  return api.get<ViajeOperador[]>(`/api/viajes/mi-empresa?${q}`, token);
}

export function programarViaje(
  token: string,
  data: {
    empresaId: number;
    busId: number;
    origen: string;
    destino: string;
    fecha: string;
    horaSalida: string;
    tarifa: number;
    tarifaEquipajeExtra?: number;
  }
) {
  return api.post<ViajeOperador>('/api/viajes', data, token);
}

export function actualizarViaje(
  token: string,
  id: number,
  data: {
    horaSalida?: string;
    tarifa?: number;
    tarifaEquipajeExtra?: number;
    observaciones?: string;
  }
) {
  return api.put<ViajeOperador>(`/api/viajes/${id}`, data, token);
}

export function cancelarViaje(token: string, id: number) {
  return api.patch<ViajeOperador>(`/api/viajes/${id}/cancelar`, {}, token);
}
