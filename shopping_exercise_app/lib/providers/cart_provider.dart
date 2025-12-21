import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final ApiService _apiService;
  late final CartService _cartService;
  Cart? _cart;
  bool _isLoading = false;
  String? _error;

  CartProvider(this._apiService) {
    _cartService = CartService(_apiService);
  }

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _cart?.itemCount ?? 0;
  double get subtotal => _cart?.subtotal ?? 0.0;

  Future<void> loadCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cart = await _cartService.getCart();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(String productId, {int quantity = 1}) async {
    try {
      await _cartService.addToCart(
        productId: productId,
        quantity: quantity,
      );
      await loadCart();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(itemId);
      return;
    }

    try {
      await _cartService.updateCartItem(
        itemId: itemId,
        quantity: quantity,
      );
      await loadCart();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeFromCart(String itemId) async {
    try {
      await _cartService.removeFromCart(itemId);
      await loadCart();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      await _cartService.clearCart();
      await loadCart();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

