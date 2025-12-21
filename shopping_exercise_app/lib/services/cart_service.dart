import '../models/cart.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class CartService {
  final ApiService _api;

  CartService(this._api);

  Future<Cart> getCart() async {
    final response = await _api.get(ApiConfig.cart);
    return Cart.fromJson(response['cart'] as Map<String, dynamic>);
  }

  Future<void> addToCart({
    required String productId,
    required int quantity,
  }) async {
    await _api.post(
      '${ApiConfig.cart}/items',  // Ruta correcta: /cart/items
      body: {
        'product_id': productId,
        'quantity': quantity,
      },
    );
    // El backend solo devuelve un mensaje, no el cartItem
    // No necesitamos retornar nada
  }

  Future<void> updateCartItem({
    required String itemId,
    required int quantity,
  }) async {
    await _api.put(
      '${ApiConfig.cart}/items/$itemId',  // Ruta correcta: /cart/items/:id
      body: {
        'quantity': quantity,
      },
    );
    // El backend solo devuelve un mensaje
  }

  Future<void> removeFromCart(String itemId) async {
    await _api.delete('${ApiConfig.cart}/items/$itemId');  // Ruta correcta: /cart/items/:id
  }

  Future<void> clearCart() async {
    await _api.delete(ApiConfig.cart);
  }
}

