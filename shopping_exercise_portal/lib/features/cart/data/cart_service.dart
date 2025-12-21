import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../auth/data/auth_service.dart';

class CartService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getCart() async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cart}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load cart');
    }
  }

  Future<void> addToCart(String productId, int quantity) async {
    final token = await _authService.getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cart}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'product_id': productId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['error']['message'] ?? 'Failed to add to cart');
    }
  }

  Future<void> updateCartItem(String itemId, int quantity) async {
    final token = await _authService.getToken();

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cart}/$itemId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'quantity': quantity}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error']['message'] ?? 'Failed to update cart');
    }
  }

  Future<void> removeFromCart(String itemId) async {
    final token = await _authService.getToken();

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cart}/$itemId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error']['message'] ?? 'Failed to remove from cart');
    }
  }

  Future<void> clearCart() async {
    final token = await _authService.getToken();

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cart}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error']['message'] ?? 'Failed to clear cart');
    }
  }
}

