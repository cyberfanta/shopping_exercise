import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/models/admin_cart.dart';
import '../../auth/data/auth_service.dart';

class AdminCartService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getAllCarts({
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _authService.getToken();
    final url = '${ApiConfig.baseUrl}${ApiConfig.adminCarts}?page=$page&limit=$limit';
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final carts = (data['carts'] as List)
          .map((cart) => AdminCart.fromJson(cart))
          .toList();
      return {
        'carts': carts,
        'pagination': data['pagination'],
      };
    } else {
      throw Exception('Failed to load carts: ${response.body}');
    }
  }

  Future<AdminCart> getCartByUserId(String userId) async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminCarts}/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AdminCart.fromJson(data['cart']);
    } else {
      throw Exception('Failed to load cart: ${response.body}');
    }
  }

  Future<void> clearUserCart(String userId) async {
    final token = await _authService.getToken();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminCarts}/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to clear cart: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getCartStats() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminCartsStats}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['stats'];
    } else {
      throw Exception('Failed to load cart stats: ${response.body}');
    }
  }
}

