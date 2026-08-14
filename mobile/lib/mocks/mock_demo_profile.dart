import '../core/auth/jwt_utils.dart';

/// Perfiles de prueba en modo demo (`USE_MOCK=true`).
enum MockDemoProfile {
  globalAdmin,
  adminEmpresa,
  cajero;

  static MockDemoProfile? fromName(String? name) {
    if (name == null) return null;
    for (final profile in MockDemoProfile.values) {
      if (profile.name == name) return profile;
    }
    return null;
  }

  static MockDemoProfile fromRoles(List<String> roles) {
    if (roles.contains(AppRoles.adminGeneral)) return MockDemoProfile.globalAdmin;
    if (roles.contains(AppRoles.adminEmpresa)) return MockDemoProfile.adminEmpresa;
    return MockDemoProfile.cajero;
  }
}

extension MockDemoProfileX on MockDemoProfile {
  /// Etiqueta corta alineada con la nomenclatura del requerimiento.
  String get code => switch (this) {
        MockDemoProfile.globalAdmin => 'GLOBAL_ADMIN',
        MockDemoProfile.adminEmpresa => 'ADMIN',
        MockDemoProfile.cajero => 'CASHIER',
      };

  String get label => switch (this) {
        MockDemoProfile.globalAdmin => 'Admin global',
        MockDemoProfile.adminEmpresa => 'Admin empresa',
        MockDemoProfile.cajero => 'Cajero',
      };

  List<String> get roles => switch (this) {
        MockDemoProfile.globalAdmin => [AppRoles.adminGeneral],
        MockDemoProfile.adminEmpresa => [AppRoles.adminEmpresa],
        MockDemoProfile.cajero => [AppRoles.cajero],
      };

  String get username => switch (this) {
        MockDemoProfile.globalAdmin => 'admin.global',
        MockDemoProfile.adminEmpresa => 'admin.wendelyn',
        MockDemoProfile.cajero => 'cajero.wendelyn',
      };

  String get displayName => switch (this) {
        MockDemoProfile.globalAdmin => 'Administrador Global',
        MockDemoProfile.adminEmpresa => 'Admin Wendelyn',
        MockDemoProfile.cajero => 'Cajero Wendelyn',
      };

  String get email => switch (this) {
        MockDemoProfile.globalAdmin => 'admin.global@transporte.com',
        MockDemoProfile.adminEmpresa => 'admin@wendelyn.com',
        MockDemoProfile.cajero => 'cajero@wendelyn.com',
      };
}

/// Perfil demo activo — leído por [mock_api] para `/api/usuarios/me`.
class MockSession {
  MockSession._();

  static MockDemoProfile profile = MockDemoProfile.globalAdmin;

  static void setProfile(MockDemoProfile value) => profile = value;
}
