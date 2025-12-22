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
  
  // Endpoints
  static const String auth = '/auth';
  static const String products = '/products';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String youtube = '/youtube';
  
  // Credenciales del usuario público (pre-autenticado)
  static const String publicUserEmail = 'user@ejemplo.com';
  static const String publicUserPassword = 'User123!';
  
  // Timeout
  static const Duration timeout = Duration(seconds: 30);
}

