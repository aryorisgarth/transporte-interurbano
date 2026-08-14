import { USE_MOCK } from '@/shared/config/env';
import { handleMockRequest } from '@/mocks/mockApi';

const BASE = import.meta.env.VITE_API_URL ?? '';

interface ApiErrorBody {
  message?: string;
  errores?: { campo: string; mensaje: string }[];
}

function parseErrorMessage(body: ApiErrorBody, status: number): string {
  if (body.errores?.length) {
    return body.errores.map((e) => `${e.campo}: ${e.mensaje}`).join('. ');
  }
  return body.message ?? `Error del servidor (${status})`;
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  if (USE_MOCK) {
    return handleMockRequest<T>(path, options);
  }

  const res = await fetch(`${BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({ message: res.statusText }));
    if (res.status === 401) {
      throw new Error('Sesión expirada o no autorizada. Inicie sesión de nuevo.');
    }
    throw new Error(parseErrorMessage(err, res.status));
  }

  if (res.status === 204) {
    return undefined as T;
  }

  return res.json();
}

export const api = {
  get: <T>(path: string, token?: string) =>
    request<T>(path, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    }),

  post: <T>(path: string, body: unknown, token?: string) =>
    request<T>(path, {
      method: 'POST',
      body: JSON.stringify(body),
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    }),

  put: <T>(path: string, body: unknown, token?: string) =>
    request<T>(path, {
      method: 'PUT',
      body: JSON.stringify(body),
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    }),

  patch: <T>(path: string, body: unknown, token?: string) =>
    request<T>(path, {
      method: 'PATCH',
      body: JSON.stringify(body),
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    }),

  delete: <T>(path: string, token?: string) =>
    request<T>(path, {
      method: 'DELETE',
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    }),
};
