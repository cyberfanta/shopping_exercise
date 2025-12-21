import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  late final AuthService _authService;
  User? _user;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;

  AuthProvider(this._apiService) {
    _authService = AuthService(_apiService);
    _initialize();
  }

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('token');
      final savedUserJson = prefs.getString('user');

      if (savedToken != null && savedUserJson != null) {
        _token = savedToken;
        _apiService.setToken(savedToken);
        // En producción, aquí deberías verificar el token con el backend
        // Por ahora, confiamos en el token guardado
      } else {
        // Auto-login con usuario público
        await _loginAsPublicUser();
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      // Si hay error, intentar login público
      await _loginAsPublicUser();
    }

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loginAsPublicUser() async {
    try {
      final result = await _authService.login(
        ApiConfig.publicUserEmail,
        ApiConfig.publicUserPassword,
      );

      _token = result['token'] as String;
      _user = result['user'] as User;

      await _saveSession();
    } catch (e) {
      debugPrint('Error logging in as public user: $e');
      // No lanzamos el error para no bloquear la app
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);

      _token = result['token'] as String;
      _user = result['user'] as User;

      await _saveSession();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );

      _token = result['token'] as String;
      _user = result['user'] as User;

      await _saveSession();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _authService.logout();
    _token = null;
    _user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');

    // Volver a loguear como usuario público
    await _loginAsPublicUser();

    notifyListeners();
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    if (_user != null) {
      // En producción, guardarías el user serializado
      await prefs.setString('user', _user!.email);
    }
  }
}

