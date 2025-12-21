class ApiConfig {
  // URL base del backend
  static const String baseUrl = 'http://localhost:3000/api';
  
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

