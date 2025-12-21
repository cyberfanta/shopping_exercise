import '../models/order.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class OrderService {
  final ApiService _api;

  OrderService(this._api);

  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await _api.get(
      ApiConfig.orders,
      queryParams: queryParams,
    );

    final orders = (response['orders'] as List<dynamic>?)
            ?.map((json) => Order.fromJson(json as Map<String, dynamic>))
            .toList() ??
        [];

    // Manejar caso cuando no hay pagination
    final pagination = response['pagination'] as Map<String, dynamic>? ?? {
      'page': page,
      'limit': limit,
      'totalItems': 0,
      'totalPages': 0,
    };

    return {
      'orders': orders,
      'pagination': pagination,
    };
  }

  Future<Order> getOrderById(String id) async {
    final response = await _api.get('${ApiConfig.orders}/$id');
    return Order.fromJson(response['order'] as Map<String, dynamic>);
  }

  Future<Order> createOrder({
    required String paymentMethod,
    required Map<String, dynamic> shippingAddress,
    String? notes,
  }) async {
    final response = await _api.post(
      ApiConfig.orders,
      body: {
        'payment_method': paymentMethod,
        'shipping_address': shippingAddress,
        if (notes != null) 'notes': notes,
      },
    );

    return Order.fromJson(response['order'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> simulatePayment(String orderId) async {
    final response = await _api.post('${ApiConfig.orders}/$orderId/pay');
    return response;
  }

  Future<void> cancelOrder(String orderId) async {
    await _api.post('${ApiConfig.orders}/$orderId/cancel');
  }
}

