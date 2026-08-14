import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../../mocks/mock_api.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${AppConfig.apiBaseUrl}$path').replace(queryParameters: query);
  }

  String _parseError(Map<String, dynamic>? body, int status) {
    if (body == null) return 'Error del servidor ($status)';
    final errores = body['errores'];
    if (errores is List && errores.isNotEmpty) {
      return errores
          .map((e) {
            if (e is Map) return '${e['campo']}: ${e['mensaje']}';
            return e.toString();
          })
          .join('. ');
    }
    if (body['message'] != null) return body['message'].toString();
    return 'Error del servidor ($status)';
  }

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    String? token,
  }) async {
    if (AppConfig.useMock) {
      return handleMockRequest(method, path, query: query, body: body);
    }

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = _uri(path, query);
    late http.Response response;

    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
      case 'POST':
        response = await _client.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        response = await _client.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PATCH':
        response = await _client.patch(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        response = await _client.delete(uri, headers: headers);
      default:
        throw ApiException('Método HTTP no soportado: $method');
    }

    if (response.statusCode == 204) return null;

    Map<String, dynamic>? jsonBody;
    if (response.body.isNotEmpty) {
      try {
        jsonBody = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {}
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        throw ApiException('Sesión expirada o no autorizada. Inicie sesión de nuevo.', statusCode: 401);
      }
      throw ApiException(_parseError(jsonBody, response.statusCode), statusCode: response.statusCode);
    }

    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<T> get<T>(String path, {Map<String, String>? query, String? token}) async {
    return await request('GET', path, query: query, token: token) as T;
  }

  Future<T> post<T>(String path, {Object? body, String? token}) async {
    return await request('POST', path, body: body, token: token) as T;
  }

  Future<T> put<T>(String path, {Object? body, String? token}) async {
    return await request('PUT', path, body: body, token: token) as T;
  }

  Future<T> patch<T>(String path, {Object? body, String? token}) async {
    return await request('PATCH', path, body: body, token: token) as T;
  }

  Future<void> delete(String path, {String? token}) async {
    await request('DELETE', path, token: token);
  }
}
