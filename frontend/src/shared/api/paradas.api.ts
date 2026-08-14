import { api } from './client';
import type { ParadaRuta } from './types';

export function listarParadas(token: string, origen: string, destino: string, horaSalida?: string) {
  const q = new URLSearchParams({ origen, destino });
  if (horaSalida) q.set('horaSalida', horaSalida);
  return api.get<ParadaRuta[]>(`/api/paradas?${q}`, token);
}

export function actualizarParada(
  token: string,
  id: number,
  data: {
    nombre: string;
    minutosDesdeSalida: number;
    latitud: number;
    longitud: number;
  }
) {
  return api.put<ParadaRuta>(`/api/paradas/${id}`, data, token);
}

export function crearParada(
  token: string,
  data: {
    origen: string;
    destino: string;
    nombre: string;
    minutosDesdeSalida: number;
    latitud: number;
    longitud: number;
  }
) {
  return api.post<ParadaRuta>('/api/paradas', data, token);
}

export function eliminarParada(token: string, id: number) {
  return api.delete<void>(`/api/paradas/${id}`, token);
}
