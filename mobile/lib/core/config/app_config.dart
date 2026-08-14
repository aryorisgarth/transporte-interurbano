import 'package:flutter/foundation.dart';

import '../auth/jwt_utils.dart';

/// Configuración de URLs — equivalente a VITE_API_URL / VITE_USE_MOCK en React.
class AppConfig {
  AppConfig._();

  static const String _apiBaseDefine = String.fromEnvironment(
    'API_BASE',
    defaultValue: '',
  );

  /// Modo demo estático (sin backend ni Keycloak). Activar con:
  /// `--dart-define=USE_MOCK=true`
  static const bool useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

  static String get apiBaseUrl {
    if (_apiBaseDefine.isNotEmpty) return _apiBaseDefine;
    if (kIsWeb) return 'http://localhost:8080';
    return 'http://10.0.2.2:8080';
  }

  /// Login proxied por Spring Boot — evita CORS del navegador hacia Keycloak.
  static String get loginUrl => '$apiBaseUrl/api/auth/token';

  static const String keycloakClientId = 'transporte-api';
}

/// Usuario demo cuando [AppConfig.useMock] es true.
class DemoUser {
  DemoUser._();

  static const name = 'Usuario Demo';
  static const username = 'demo';
  static const email = 'demo@transporte.com';
  static const roles = [
    AppRoles.adminGeneral,
    AppRoles.adminEmpresa,
    AppRoles.cajero,
  ];
}
