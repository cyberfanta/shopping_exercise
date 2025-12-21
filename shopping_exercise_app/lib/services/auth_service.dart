import '../models/user.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class AuthService {
  final ApiService _api;

  AuthService(this._api);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.post(
      '${ApiConfig.auth}/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    final token = response['token'] as String;
    final user = User.fromJson(response['user'] as Map<String, dynamic>);

    _api.setToken(token);

    return {
      'token': token,
      'user': user,
    };
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final response = await _api.post(
      '${ApiConfig.auth}/register',
      body: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        if (phone != null) 'phone': phone,
      },
    );

    final token = response['token'] as String;
    final user = User.fromJson(response['user'] as Map<String, dynamic>);

    _api.setToken(token);

    return {
      'token': token,
      'user': user,
    };
  }

  void logout() {
    _api.setToken(null);
  }
}

