import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/category.dart';
import '../../../../core/models/product.dart';
import '../../data/product_service.dart';

// States
abstract class ProductsState {}

class ProductsInitial extends ProductsState {}

class ProductsLoading extends ProductsState {}

class ProductsLoaded extends ProductsState {
  final List<Product> products;
  final Map<String, dynamic> pagination;
  final List<Category> categories;

  ProductsLoaded({
    required this.products,
    required this.pagination,
    required this.categories,
  });
}

class ProductsError extends ProductsState {
  final String message;

  ProductsError(this.message);
}

// Cubit
class ProductsCubit extends Cubit<ProductsState> {
  final ProductService _productService = ProductService();

  ProductsCubit() : super(ProductsInitial());

  Future<void> loadProducts({
    int page = 1,
    String? categoryId,
    String? search,
  }) async {
    try {
      emit(ProductsLoading());
      
      final result = await _productService.getProducts(
        page: page,
        limit: 20,
        categoryId: categoryId,
        search: search,
      );
      
      final categories = await _productService.getCategories();

      emit(ProductsLoaded(
        products: result['products'],
        pagination: result['pagination'],
        categories: categories,
      ));
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }

  Future<void> createProduct(Map<String, dynamic> productData) async {
    try {
      await _productService.createProduct(productData);
      await loadProducts();
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> productData) async {
    try {
      await _productService.updateProduct(id, productData);
      await loadProducts();
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _productService.deleteProduct(id);
      await loadProducts();
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }

  Future<List<Map<String, dynamic>>> searchYoutubeVideos(String query) async {
    return await _productService.searchYoutubeVideos(query);
  }
}


