import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/viaje.dart';

class TransporteApiException implements Exception {
  TransporteApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class TransporteApi {
  TransporteApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: query);
  }

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  void _check(http.Response response, {int ok = 200}) {
    if (response.statusCode != ok) {
      String msg = 'Error ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] != null) msg = body['message'].toString();
      } catch (_) {}
      throw TransporteApiException(msg, statusCode: response.statusCode);
    }
  }

  Future<void> healthCheck() async {
    final response = await _client.get(_uri('/api/health'));
    _check(response);
  }

  Future<List<ViajeDisponible>> buscarViajes({
    required String origen,
    required String destino,
    required String fecha,
  }) async {
    final response = await _client.get(
      _uri('/api/publico/viajes', {'origen': origen, 'destino': destino, 'fecha': fecha}),
    );
    _check(response);
    final list = _decode(response) as List<dynamic>;
    return list.map((e) => ViajeDisponible.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DetalleViaje> detalleViaje(int viajeId) async {
    final response = await _client.get(_uri('/api/publico/viajes/$viajeId'));
    _check(response);
    return DetalleViaje.fromJson(_decode(response) as Map<String, dynamic>);
  }
}
