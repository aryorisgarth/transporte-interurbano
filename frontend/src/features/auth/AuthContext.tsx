import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react';
import { extractRolesFromToken } from '@/shared/utils/jwt';
import { USE_MOCK, DEMO_USER } from '@/shared/config/env';
import { buildMockJwt } from '@/mocks/mockToken';

interface AuthState {
  token: string | null;
  username: string | null;
  roles: string[];
  login: (token: string, username: string) => void;
  logout: () => void;
  isAuthenticated: boolean;
  hasRole: (...roles: string[]) => boolean;
  isMockMode: boolean;
}

const AuthContext = createContext<AuthState | null>(null);

const TOKEN_KEY = 'kc_token';
const USER_KEY = 'kc_username';
const ROLES_KEY = 'kc_roles';

function loadRoles(): string[] {
  try {
    const raw = sessionStorage.getItem(ROLES_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function createMockSession() {
  const token = buildMockJwt(DEMO_USER.username, DEMO_USER.email, DEMO_USER.roles);
  sessionStorage.setItem(TOKEN_KEY, token);
  sessionStorage.setItem(USER_KEY, DEMO_USER.username);
  sessionStorage.setItem(ROLES_KEY, JSON.stringify(DEMO_USER.roles));
  return { token, username: DEMO_USER.username, roles: DEMO_USER.roles };
}

function loadInitialSession() {
  if (USE_MOCK) {
    return createMockSession();
  }
  const token = sessionStorage.getItem(TOKEN_KEY);
  const username = sessionStorage.getItem(USER_KEY);
  const roles = loadRoles();
  if (token && roles.length === 0) {
    return { token, username, roles: extractRolesFromToken(token) };
  }
  return { token, username, roles };
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const initial = loadInitialSession();
  const [token, setToken] = useState<string | null>(initial.token);
  const [username, setUsername] = useState<string | null>(initial.username);
  const [roles, setRoles] = useState<string[]>(initial.roles);

  const login = useCallback((t: string, user: string) => {
    const r = extractRolesFromToken(t);
    sessionStorage.setItem(TOKEN_KEY, t);
    sessionStorage.setItem(USER_KEY, user);
    sessionStorage.setItem(ROLES_KEY, JSON.stringify(r));
    setToken(t);
    setUsername(user);
    setRoles(r);
  }, []);

  const logout = useCallback(() => {
    sessionStorage.removeItem(TOKEN_KEY);
    sessionStorage.removeItem(USER_KEY);
    sessionStorage.removeItem(ROLES_KEY);
    setToken(null);
    setUsername(null);
    setRoles([]);
  }, []);

  const hasRole = useCallback(
    (...required: string[]) => {
      const effective = token ? extractRolesFromToken(token) : roles;
      return required.some((r) => effective.includes(r));
    },
    [token, roles]
  );

  const value = useMemo(
    () => ({
      token,
      username,
      roles,
      login,
      logout,
      isAuthenticated: !!token,
      hasRole,
      isMockMode: USE_MOCK,
    }),
    [token, username, roles, login, logout, hasRole]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth debe usarse dentro de AuthProvider');
  return ctx;
}
