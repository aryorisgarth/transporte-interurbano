import { api } from './client';
import type { UsuarioPerfil } from './types';

export function obtenerPerfil(token: string) {
  return api.get<UsuarioPerfil>('/api/usuarios/me', token);
}

export function listarOperadores(token: string, empresaId?: number) {
  const q = empresaId ? `?empresaId=${empresaId}` : '';
  return api.get<UsuarioPerfil[]>(`/api/usuarios${q}`, token);
}

export function crearOperador(
  token: string,
  data: {
    empresaId: number;
    nombreUsuario: string;
    nombreCompleto: string;
    password: string;
    roles: string[];
    email?: string;
    sede?: string;
  }
) {
  return api.post<UsuarioPerfil>('/api/usuarios', data, token);
}

export function actualizarOperador(
  token: string,
  id: number,
  data: {
    activo?: boolean;
    nombreCompleto?: string;
    sede?: string;
    reservaExcepcional?: boolean;
  }
) {
  return api.patch<UsuarioPerfil>(`/api/usuarios/${id}`, data, token);
}
