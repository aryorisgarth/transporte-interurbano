import 'dart:convert';

class AppRoles {
  static const cajero = 'CAJERO';
  static const adminEmpresa = 'ADMIN_EMPRESA';
  static const adminGeneral = 'ADMIN_GENERAL';
  static const reservaExcepcional = 'RESERVA_EXCEPCIONAL';
}

Map<String, dynamic>? decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    var payload = parts[1];
    final mod = payload.length % 4;
    if (mod > 0) payload += '=' * (4 - mod);
    final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
    return jsonDecode(utf8.decode(base64.decode(normalized))) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

List<String> extractRolesFromToken(String token) {
  final payload = decodeJwtPayload(token);
  if (payload == null) return [];

  final roles = <String>{};

  final realmAccess = payload['realm_access'];
  if (realmAccess is Map && realmAccess['roles'] is List) {
    for (final r in realmAccess['roles'] as List) {
      roles.add(r.toString());
    }
  }

  final resourceAccess = payload['resource_access'];
  if (resourceAccess is Map) {
    for (final client in resourceAccess.values) {
      if (client is Map && client['roles'] is List) {
        for (final r in client['roles'] as List) {
          roles.add(r.toString());
        }
      }
    }
  }

  return roles.toList();
}

bool isAdmin(List<String> roles) =>
    roles.contains(AppRoles.adminEmpresa) || roles.contains(AppRoles.adminGeneral);

bool esAdminGlobal(List<String> roles) => roles.contains(AppRoles.adminGeneral);

bool esAdminEmpresa(List<String> roles) =>
    roles.contains(AppRoles.adminEmpresa) && !roles.contains(AppRoles.adminGeneral);

bool puedeUsarPanelCajero(List<String> roles) =>
    roles.contains(AppRoles.cajero) &&
    !roles.contains(AppRoles.adminEmpresa) &&
    !roles.contains(AppRoles.adminGeneral);

String rutaInicio(List<String> roles, {String? from}) {
  if (from != null && from.startsWith('/admin') && isAdmin(roles)) return from;
  if (from != null && from.startsWith('/cajero') && puedeUsarPanelCajero(roles)) {
    return from;
  }
  if (isAdmin(roles)) return '/admin';
  if (puedeUsarPanelCajero(roles)) return '/cajero';
  return '/acceso/login';
}

String roleLabel(String role) {
  switch (role) {
    case AppRoles.adminGeneral:
      return 'Admin plataforma';
    case AppRoles.adminEmpresa:
      return 'Admin cooperativa';
    case AppRoles.cajero:
      return 'Cajero';
    default:
      return role;
  }
}
