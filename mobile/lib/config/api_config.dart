/// Backend y Keycloak en la PC host — emulador Android usa 10.0.2.2.
class ApiConfig {
  static const String _compileOverride = String.fromEnvironment('API_BASE');
  static const String keycloakRealmPath = '/realms/transporte-bluefields';
  static const int keycloakPort = 8180;

  /// IP del host vista desde el emulador Android (equivale a localhost en la PC).
  static const defaultBaseUrl = 'http://10.0.2.2:8080';

  static String get baseUrl {
    if (_compileOverride.isNotEmpty) {
      return _normalize(_compileOverride);
    }
    return defaultBaseUrl;
  }

  static String get keycloakRealmUrl {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}:$keycloakPort$keycloakRealmPath';
  }

  static String _normalize(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
