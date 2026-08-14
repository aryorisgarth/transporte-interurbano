import { api } from './client';
import type { IngresosReporte, OcupacionViaje } from './types';

export function reporteOcupacion(token: string, fecha: string, empresaId?: number) {
  const q = new URLSearchParams({ fecha });
  if (empresaId) q.set('empresaId', String(empresaId));
  return api.get<OcupacionViaje[]>(`/api/reportes/ocupacion?${q}`, token);
}

export function reporteIngresos(token: string, desde: string, hasta: string, empresaId?: number) {
  const q = new URLSearchParams({ desde, hasta });
  if (empresaId) q.set('empresaId', String(empresaId));
  return api.get<IngresosReporte>(`/api/reportes/ingresos?${q}`, token);
}
