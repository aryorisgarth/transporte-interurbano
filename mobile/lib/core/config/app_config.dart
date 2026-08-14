import 'package:flutter/foundation.dart';

/// Configuración de URLs — equivalente a VITE_API_URL / VITE_KEYCLOAK_URL en React.
class AppConfig {
  AppConfig._();

  static const String _apiBaseDefine = String.fromEnvironment(
    'API_BASE',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_apiBaseDefine.isNotEmpty) return _apiBaseDefine;
    if (kIsWeb) return 'http://localhost:8080'; // Cambiado a localhost para evitar problemas de CORS
    return 'http://10.0.2.2:8080';
  }

  /// Login proxied por Spring Boot — evita CORS del navegador hacia Keycloak.
  static String get loginUrl => '$apiBaseUrl/api/auth/token';

  static const String keycloakClientId = 'transporte-api';
}