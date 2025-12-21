import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  final String baseUrl;
  String? _token;

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http
          .get(uri, headers: _headers)
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> put(String endpoint,
      {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .put(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .delete(uri, headers: _headers)
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Error de conexión: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (response.body.isEmpty) {
      if (statusCode >= 200 && statusCode < 300) {
        return {'success': true};
      } else {
        throw ApiException(
          'Error del servidor',
          statusCode: statusCode,
        );
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (statusCode >= 200 && statusCode < 300) {
      return data;
    } else {
      // Manejar errores del backend
      String errorMessage = 'Error desconocido';

      if (data.containsKey('error')) {
        final error = data['error'];
        if (error is Map) {
          errorMessage = error['message'] ?? errorMessage;
        } else if (error is String) {
          errorMessage = error;
        }
      } else if (data.containsKey('errors') && data['errors'] is List) {
        final errors = data['errors'] as List;
        if (errors.isNotEmpty) {
          errorMessage = errors
              .map((e) => e is Map ? e['msg'] ?? e.toString() : e.toString())
              .join(', ');
        }
      } else if (data.containsKey('message')) {
        errorMessage = data['message'] as String;
      }

      throw ApiException(errorMessage, statusCode: statusCode);
    }
  }
}

