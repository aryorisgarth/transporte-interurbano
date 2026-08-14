import 'dart:convert';

import '../core/config/app_config.dart';

/// JWT sintético para modo demo (sin verificación de firma; solo UI de roles).
String buildMockJwt({
  required String username,
  required String email,
  required List<String> roles,
}) {
  String encodePart(Object value) {
    final normalized = base64Url.encode(utf8.encode(jsonEncode(value)));
    return normalized.replaceAll('=', '');
  }

  final header = encodePart({'alg': 'none', 'typ': 'JWT'});
  final payload = encodePart({
    'sub': username,
    'preferred_username': username,
    'email': email,
    'realm_access': {'roles': roles},
  });
  return '$header.$payload.mock-signature';
}

String demoMockToken() => buildMockJwt(
      username: DemoUser.username,
      email: DemoUser.email,
      roles: DemoUser.roles,
    );
