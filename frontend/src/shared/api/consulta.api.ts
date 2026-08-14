import { api } from './client';
import type { DetalleViaje, ViajeDisponible } from './types';

export function buscarViajes(origen: string, destino: string, fecha: string) {
  const params = new URLSearchParams({ origen, destino, fecha });
  return api.get<ViajeDisponible[]>(`/api/publico/viajes?${params}`);
}

export function detalleViaje(viajeId: number) {
  return api.get<DetalleViaje>(`/api/publico/viajes/${viajeId}`);
}

export function tarifaReferenciaUsd(monto: number) {
  return api.get<{ equivalenteUsd: number }>(`/api/externo/tarifa-referencia-usd?monto=${monto}`);
}
