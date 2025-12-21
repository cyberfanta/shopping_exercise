import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/models/order.dart';
import '../../auth/data/auth_service.dart';

class OrderService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final token = await _authService.getToken();

    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
    };

    // Use admin endpoint to get all orders with user info
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminOrders}')
        .replace(queryParameters: queryParams);

    print('🌐 OrderService: GET $uri');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('📡 Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final orders = (data['orders'] as List)
          .map((json) => Order.fromJson(json))
          .toList();
      
      print('✅ Parsed ${orders.length} orders successfully');
      
      return {
        'orders': orders,
        'pagination': data['pagination'] ?? {
          'page': 1,
          'limit': 20,
          'totalItems': orders.length,
          'totalPages': 1,
        },
      };
    } else {
      print('❌ Failed to load orders: ${response.statusCode}');
      throw Exception('Failed to load orders');
    }
  }

  Future<Order> getOrderById(String id) async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminOrders}/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Order.fromJson(data['order']);
    } else {
      throw Exception('Failed to load order');
    }
  }

  Future<void> cancelOrder(String id) async {
    final token = await _authService.getToken();

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminOrders}/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error']['message'] ?? 'Failed to cancel order');
    }
  }
}

