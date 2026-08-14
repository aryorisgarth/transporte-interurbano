import { api } from './client';
import type { AsientoBus, AsientoViaje, Bus } from './types';

export function busesPorEmpresa(token: string, empresaId: number, sede?: string) {
  const q = new URLSearchParams({ empresaId: String(empresaId) });
  if (sede) q.set('sede', sede);
  return api.get<Bus[]>(`/api/buses?${q}`, token);
}

export function busesMiEmpresa(token: string, sede?: string) {
  const q = sede ? `?sede=${encodeURIComponent(sede)}` : '';
  return api.get<Bus[]>(`/api/buses/mi-empresa${q}`, token);
}

export function crearBus(
  token: string,
  data: {
    empresaId: number;
    numeroInterno: string;
    placa: string;
    capacidad: number;
    sede: string;
    fotoUrl?: string;
  }
) {
  return api.post<Bus>('/api/buses', data, token);
}

export function obtenerBus(token: string, id: number) {
  return api.get<Bus>(`/api/buses/${id}`, token);
}

export function actualizarBus(
  token: string,
  id: number,
  data: {
    numeroInterno: string;
    placa: string;
    sede: string;
    fotoUrl?: string;
    activo?: boolean;
  }
) {
  return api.put<Bus>(`/api/buses/${id}`, data, token);
}

export function actualizarAsientoBus(
  token: string,
  busId: number,
  asientoId: number,
  data: { numero: number; fila: number; posicion: AsientoViaje['posicion'] }
) {
  return api.put<AsientoBus>(`/api/buses/${busId}/asientos/${asientoId}`, data, token);
}
