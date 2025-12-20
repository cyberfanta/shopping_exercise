import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/models/user.dart';
import '../../auth/data/auth_service.dart';

class UserService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 10,
    String? role,
    String? search,
  }) async {
    final token = await _authService.getToken();
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (role != null) 'role': role,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.users}')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final users = (data['users'] as List)
          .map((json) => User.fromJson(json))
          .toList();
      return {
        'users': users,
        'pagination': data['pagination'],
      };
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<User> updateUser(String id, Map<String, dynamic> userData) async {
    final token = await _authService.getToken();

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.users}/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['user']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error']['message'] ?? 'Failed to update user');
    }
  }

  Future<void> deleteUser(String id) async {
    final token = await _authService.getToken();

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.users}/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error']['message'] ?? 'Failed to delete user');
    }
  }
}


