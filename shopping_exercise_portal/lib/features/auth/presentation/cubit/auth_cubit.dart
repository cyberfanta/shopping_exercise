import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/user.dart';
import '../../data/auth_service.dart';

// States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final String token;

  AuthAuthenticated({required this.user, required this.token});
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService = AuthService();

  AuthCubit() : super(AuthInitial()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    emit(AuthLoading());
    final auth = await _authService.checkAuth();
    
    if (auth != null) {
      emit(AuthAuthenticated(user: auth['user'], token: auth['token']));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    try {
      emit(AuthLoading());
      final result = await _authService.login(email, password);
      emit(AuthAuthenticated(user: result['user'], token: result['token']));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    emit(AuthUnauthenticated());
  }
}


