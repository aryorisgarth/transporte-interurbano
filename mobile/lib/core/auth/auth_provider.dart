import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth_api.dart';
import '../config/app_config.dart';
import '../../mocks/mock_demo_profile.dart';
import '../../mocks/mock_token.dart';
import 'jwt_utils.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider();

  static const _tokenKey = 'kc_token';
  static const _usernameKey = 'kc_username';
  static const _rolesKey = 'kc_roles';
  static const _mockProfileKey = 'mock_demo_profile';

  String? _token;
  String? _username;
  List<String> _roles = [];
  MockDemoProfile? _mockProfile;

  String? get token => _token;
  String? get username => _username;
  List<String> get roles => List.unmodifiable(_roles);
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isMockMode => AppConfig.useMock;
  MockDemoProfile? get mockProfile => AppConfig.useMock ? _mockProfile : null;

  bool hasRole(String role) => _roles.contains(role);

  bool hasAnyRole(List<String> required) =>
      required.any((r) => _roles.contains(r));

  Future<void> _persistMockSession(MockDemoProfile profile) async {
    _mockProfile = profile;
    MockSession.setProfile(profile);

    final token = mockJwtForProfile(profile);
    _token = token;
    _username = profile.username;
    _roles = List<String>.from(profile.roles);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, profile.username);
    await prefs.setStringList(_rolesKey, _roles);
    await prefs.setString(_mockProfileKey, profile.name);
  }

  Future<void> switchMockProfile(MockDemoProfile profile) async {
    if (!AppConfig.useMock) return;
    await _persistMockSession(profile);
    notifyListeners();
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _username = prefs.getString(_usernameKey);
    _roles = prefs.getStringList(_rolesKey) ?? [];

    if (_token != null && _roles.isEmpty) {
      _roles = extractRolesFromToken(_token!);
    }

    if (AppConfig.useMock) {
      final saved = MockDemoProfile.fromName(prefs.getString(_mockProfileKey));
      final profile = saved ?? MockDemoProfile.globalAdmin;

      final needsRefresh = _token == null ||
          _token!.isEmpty ||
          MockDemoProfile.fromRoles(_roles) != profile;

      _mockProfile = profile;
      MockSession.setProfile(profile);

      if (needsRefresh) {
        await _persistMockSession(profile);
      }
    }

    notifyListeners();
  }

  Future<void> login(String user, String pass) async {
    final token = await AuthApi.login(user, pass);
    final roles = extractRolesFromToken(token);
    if (roles.isEmpty) {
      throw Exception('No se pudieron obtener permisos.');
    }

    _token = token;
    _roles = roles;

    if (AppConfig.useMock) {
      final profile = _mockProfile ?? MockDemoProfile.fromRoles(roles);
      _mockProfile = profile;
      _username = profile.username;
      await _persistMockSession(profile);
    } else {
      _username = user.trim();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_usernameKey, _username!);
      await prefs.setStringList(_rolesKey, roles);
    }

    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _username = null;
    _roles = [];
    _mockProfile = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_rolesKey);
    await prefs.remove(_mockProfileKey);
    notifyListeners();
  }
}
