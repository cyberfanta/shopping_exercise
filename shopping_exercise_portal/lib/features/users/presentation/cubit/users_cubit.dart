import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/user.dart';
import '../../data/user_service.dart';

// States
abstract class UsersState {}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  final List<User> users;
  final Map<String, dynamic> pagination;

  UsersLoaded({
    required this.users,
    required this.pagination,
  });
}

class UsersError extends UsersState {
  final String message;

  UsersError(this.message);
}

// Cubit
class UsersCubit extends Cubit<UsersState> {
  final UserService _userService = UserService();

  UsersCubit() : super(UsersInitial());

  Future<void> loadUsers({
    int page = 1,
    String? role,
    String? search,
  }) async {
    try {
      emit(UsersLoading());
      
      final result = await _userService.getUsers(
        page: page,
        limit: 20,
        role: role,
        search: search,
      );

      emit(UsersLoaded(
        users: result['users'],
        pagination: result['pagination'],
      ));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> updateUser(String id, Map<String, dynamic> userData) async {
    try {
      await _userService.updateUser(id, userData);
      await loadUsers();
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _userService.deleteUser(id);
      await loadUsers();
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }
}


