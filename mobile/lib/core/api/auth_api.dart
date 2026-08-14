import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_client.dart';

class AuthApi {
  /// Login vía backend (evita CORS Flutter Web → Keycloak).
  static Future<String> login(String username, String password) async {
    final user = username.trim();
    final pass = password;
    if (user.isEmpty || pass.isEmpty) {
      throw ApiException('Usuario y contraseña son obligatorios.');
    }

    http.Response response;
    try {
      response = await http.post(
        Uri.parse(AppConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': user, 'password': pass}),
      );
    } catch (_) {
      throw ApiException(
        'No se pudo conectar al servidor. Verifique backend (8080) y Keycloak (8180).',
      );
    }

    Map<String, dynamic>? data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>?;
    } catch (_) {}

    if (response.statusCode != 200) {
      final msg = data?['message']?.toString() ?? 'Usuario o contraseña incorrectos.';
      throw ApiException(msg);
    }

    final token = data?['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException('No se recibió token de acceso.');
    }
    return token;
  }
}
