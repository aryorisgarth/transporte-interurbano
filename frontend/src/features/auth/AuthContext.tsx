import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react';
import { extractRolesFromToken } from '@/shared/utils/jwt';

interface AuthState {
  token: string | null;
  username: string | null;
  roles: string[];
  login: (token: string, username: string) => void;
  logout: () => void;
  isAuthenticated: boolean;
  hasRole: (...roles: string[]) => boolean;
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

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(() => sessionStorage.getItem(TOKEN_KEY));
  const [username, setUsername] = useState<string | null>(() => sessionStorage.getItem(USER_KEY));
  const [roles, setRoles] = useState<string[]>(loadRoles);

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
    () => ({ token, username, roles, login, logout, isAuthenticated: !!token, hasRole }),
    [token, username, roles, login, logout, hasRole]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth debe usarse dentro de AuthProvider');
  return ctx;
}
