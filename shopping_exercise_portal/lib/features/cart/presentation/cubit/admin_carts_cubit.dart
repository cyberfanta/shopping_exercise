import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/admin_cart.dart';
import '../../data/admin_cart_service.dart';

// States
abstract class AdminCartsState {}

class AdminCartsInitial extends AdminCartsState {}

class AdminCartsLoading extends AdminCartsState {}

class AdminCartsLoaded extends AdminCartsState {
  final List<AdminCart> carts;
  final Map<String, dynamic> pagination;

  AdminCartsLoaded({
    required this.carts,
    required this.pagination,
  });
}

class AdminCartsError extends AdminCartsState {
  final String message;

  AdminCartsError(this.message);
}

// Cubit
class AdminCartsCubit extends Cubit<AdminCartsState> {
  final AdminCartService _adminCartService = AdminCartService();

  AdminCartsCubit() : super(AdminCartsInitial());

  Future<void> loadCarts({
    int page = 1,
    bool isLoadMore = false,
  }) async {
    try {
      print('🛒 AdminCartsCubit: Loading carts (page: $page, isLoadMore: $isLoadMore)');
      
      if (!isLoadMore) {
        emit(AdminCartsLoading());
      }

      final result = await _adminCartService.getAllCarts(
        page: page,
        limit: 20,
      );

      print('🛒 AdminCartsCubit: Received ${result['carts'].length} carts');
      print('🛒 AdminCartsCubit: Pagination: ${result['pagination']}');

      if (isLoadMore && state is AdminCartsLoaded) {
        final currentLoadedState = state as AdminCartsLoaded;
        emit(AdminCartsLoaded(
          carts: [...currentLoadedState.carts, ...result['carts']],
          pagination: result['pagination'],
        ));
      } else {
        emit(AdminCartsLoaded(
          carts: result['carts'],
          pagination: result['pagination'],
        ));
      }
      
      print('🛒 AdminCartsCubit: State emitted successfully');
    } catch (e) {
      print('❌ AdminCartsCubit ERROR: $e');
      emit(AdminCartsError(e.toString()));
    }
  }

  Future<void> clearCart(String userId) async {
    try {
      await _adminCartService.clearUserCart(userId);
      // Reload carts after clearing
      await loadCarts();
    } catch (e) {
      emit(AdminCartsError(e.toString()));
    }
  }
}

