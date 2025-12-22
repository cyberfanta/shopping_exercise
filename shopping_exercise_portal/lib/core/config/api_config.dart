import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // URL base del backend
  // En web: usa ruta relativa que funciona con el proxy de nginx
  // En desarrollo local (mobile/desktop): usa localhost
  static String get baseUrl {
    if (kIsWeb) {
      // En web, usar ruta relativa - nginx proxy maneja /api -> localhost:3000
      return '/api';
    } else {
      // En desarrollo local (mobile/desktop), usar localhost
      return 'http://localhost:3000/api';
    }
  }
  
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';
  
  static const String products = '/products';
  static const String categories = '/categories';
  
  static const String users = '/users';
  
  static const String youtubeSearch = '/youtube/search';
  static const String youtubeVideo = '/youtube/video';
  
  static const String cart = '/cart';
  static const String orders = '/orders';
  
  // Admin endpoints
  static const String adminCarts = '/admin/carts';
  static const String adminCartsStats = '/admin/carts-stats';
  static const String adminOrders = '/admin/orders';
}


