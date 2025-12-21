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
      final user = auth['user'] as User;
      
      // Verificar que el usuario sea admin o superadmin
      if (user.role != 'admin' && user.role != 'superadmin') {
        await _authService.logout();
        emit(AuthUnauthenticated());
        return;
      }
      
      emit(AuthAuthenticated(user: user, token: auth['token']));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    try {
      emit(AuthLoading());
      final result = await _authService.login(email, password);
      final user = result['user'] as User;
      
      // Verificar que el usuario sea admin o superadmin
      if (user.role != 'admin' && user.role != 'superadmin') {
        emit(AuthError('Acceso denegado. Se requieren privilegios de administrador.'));
        emit(AuthUnauthenticated());
        return;
      }
      
      emit(AuthAuthenticated(user: user, token: result['token']));
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


