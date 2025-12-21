import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/api_config.dart';
import '../../../core/models/user.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authLogin}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final user = User.fromJson(data['user']);
      
      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user', jsonEncode(user.toJson()));
      
      return {'user': user, 'token': token};
    } else {
      final error = jsonDecode(response.body);
      
      // Manejar errores de validación
      if (error['errors'] != null && error['errors'] is List) {
        final errors = error['errors'] as List;
        if (errors.isNotEmpty) {
          final firstError = errors[0];
          throw Exception(firstError['msg'] ?? 'Error de validación');
        }
      }
      
      // Manejar errores normales
      throw Exception(error['error']?['message'] ?? 'Error al iniciar sesión');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  Future<Map<String, dynamic>?> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');
    
    if (token == null || userJson == null) return null;
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authMe}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        return {'user': user, 'token': token};
      }
    } catch (e) {
      // Token expired or invalid
    }
    
    await logout();
    return null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}


