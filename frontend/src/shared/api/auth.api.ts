const KEYCLOAK_BASE =
  import.meta.env.VITE_KEYCLOAK_URL ??
  (import.meta.env.DEV
    ? '/realms/transporte-bluefields'
    : 'http://localhost:8180/realms/transporte-bluefields');

export async function loginKeycloak(username: string, password: string): Promise<string> {
  const user = username.trim();
  const pass = password;

  if (!user || !pass) {
    throw new Error('Usuario y contraseña son obligatorios.');
  }

  const body = new URLSearchParams({
    client_id: 'transporte-api',
    grant_type: 'password',
    username: user,
    password: pass,
  });

  let res: Response;
  try {
    res = await fetch(`${KEYCLOAK_BASE}/protocol/openid-connect/token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  } catch {
    throw new Error(
      'No se pudo conectar con Keycloak. Verifique que Docker esté activo (puerto 8180) y reinicie el frontend.'
    );
  }

  if (!res.ok) {
    const err = await res.json().catch(() => null);
    const code = err?.error as string | undefined;
    if (code === 'invalid_grant') {
      throw new Error(
        'Usuario o contraseña incorrectos. Use el nombre de usuario (ej. admin.global), no el correo ni admin/admin de Keycloak. Contraseña demo: password'
      );
    }
    throw new Error(err?.error_description ?? err?.error ?? 'Credenciales inválidas');
  }

  return (await res.json()).access_token as string;
}
