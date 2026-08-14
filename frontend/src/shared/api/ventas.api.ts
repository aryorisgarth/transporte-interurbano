import { api } from './client';
import type { ManifiestoPasajero, VentaRequest, VentaResponse } from './types';

export function crearVenta(data: VentaRequest, token: string) {
  return api.post<VentaResponse>('/api/ventas', data, token);
}

export function manifiestoPasajeros(
  token: string,
  params: { fecha: string; viajeId?: number; busId?: number; empresaId?: number }
) {
  const q = new URLSearchParams({ fecha: params.fecha });
  if (params.viajeId) q.set('viajeId', String(params.viajeId));
  if (params.busId) q.set('busId', String(params.busId));
  if (params.empresaId) q.set('empresaId', String(params.empresaId));
  return api.get<ManifiestoPasajero[]>(`/api/pasajeros/manifiesto?${q}`, token);
}

export function crearReservaExcepcional(
  token: string,
  data: {
    viajeAsientoId: number;
    compradorNombre: string;
    compradorCedula: string;
    compradorTelefono?: string;
    motivo: string;
    horasExpiracion: number;
  }
) {
  return api.post<{ id: number; numeroAsiento: number }>('/api/reservas-excepcionales', data, token);
}
