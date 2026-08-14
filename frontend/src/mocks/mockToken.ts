function encodePart(value: unknown): string {
  return btoa(JSON.stringify(value)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

/** JWT sintético para modo demo (sin verificación de firma; solo UI de roles). */
export function buildMockJwt(username: string, email: string, roles: string[]): string {
  const header = encodePart({ alg: 'none', typ: 'JWT' });
  const payload = encodePart({
    sub: username,
    preferred_username: username,
    email,
    realm_access: { roles },
  });
  return `${header}.${payload}.mock-signature`;
}
