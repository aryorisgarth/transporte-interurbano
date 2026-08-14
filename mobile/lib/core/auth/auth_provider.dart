import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth_api.dart';
import '../config/app_config.dart';
import '../../mocks/mock_token.dart';
import 'jwt_utils.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider();

  static const _tokenKey = 'kc_token';
  static const _usernameKey = 'kc_username';
  static const _rolesKey = 'kc_roles';

  String? _token;
  String? _username;
  List<String> _roles = [];

  String? get token => _token;
  String? get username => _username;
  List<String> get roles => List.unmodifiable(_roles);
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isMockMode => AppConfig.useMock;

  bool hasRole(String role) => _roles.contains(role);

  bool hasAnyRole(List<String> required) =>
      required.any((r) => _roles.contains(r));

  Future<void> _persistMockSession() async {
    final token = demoMockToken();
    _token = token;
    _username = DemoUser.username;
    _roles = List<String>.from(DemoUser.roles);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, DemoUser.username);
    await prefs.setStringList(_rolesKey, _roles);
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _username = prefs.getString(_usernameKey);
    _roles = prefs.getStringList(_rolesKey) ?? [];

    if (_token != null && _roles.isEmpty) {
      _roles = extractRolesFromToken(_token!);
    }

    if (AppConfig.useMock && (_token == null || _token!.isEmpty)) {
      await _persistMockSession();
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
    _username = AppConfig.useMock ? DemoUser.username : user.trim();
    _roles = roles;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, _username!);
    await prefs.setStringList(_rolesKey, roles);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _username = null;
    _roles = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_rolesKey);
    notifyListeners();
  }
}
