import 'dart:convert';

import 'mock_demo_profile.dart';

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

String mockJwtForProfile(MockDemoProfile profile) => buildMockJwt(
      username: profile.username,
      email: profile.email,
      roles: profile.roles,
    );
