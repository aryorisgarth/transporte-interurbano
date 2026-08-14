import { api } from './client';
import type { DetalleCooperativa, Empresa, ResumenEmpresa } from './types';

export function listarEmpresas(token: string) {
  return api.get<Empresa[]>('/api/empresas', token);
}

export function miEmpresa(token: string) {
  return api.get<Empresa>('/api/empresas/mi-empresa', token);
}

export function obtenerEmpresa(token: string, id: number) {
  return api.get<Empresa>(`/api/empresas/${id}`, token);
}

export function actualizarEmpresa(
  token: string,
  id: number,
  data: {
    nombre: string;
    telefono?: string;
    correo?: string;
    tarifaEquipajeExtra?: number;
    logoUrl?: string;
  }
) {
  return api.put<Empresa>(`/api/empresas/${id}`, data, token);
}

export function crearEmpresa(
  token: string,
  data: {
    nombre: string;
    telefono?: string;
    correo?: string;
    tarifaEquipajeExtra?: number;
    logoUrl?: string;
  }
) {
  return api.post<Empresa>('/api/empresas', data, token);
}

export function desactivarEmpresa(token: string, id: number) {
  return api.patch<{ message: string; id: string }>(`/api/empresas/${id}/desactivar`, {}, token);
}

export function resumenPlataforma(token: string) {
  return api.get<ResumenEmpresa[]>('/api/empresas/resumen-plataforma', token);
}

export function detalleCooperativa(token: string, empresaId: number) {
  return api.get<DetalleCooperativa>(`/api/empresas/${empresaId}/detalle-plataforma`, token);
}
