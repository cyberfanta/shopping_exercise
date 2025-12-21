import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService;
  late final ProductService _productService;
  
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _searchQuery;
  String? _selectedCategoryId;
  String? _error;

  ProductProvider(this._apiService) {
    _productService = ProductService(_apiService);
  }

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get searchQuery => _searchQuery;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get error => _error;

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _products = [];
      _hasMore = true;
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _productService.getProducts(
        page: _currentPage,
        limit: 20,
        categoryId: _selectedCategoryId,
        search: _searchQuery,
      );

      final newProducts = result['products'] as List<Product>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      if (refresh) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      _currentPage++;
      _hasMore = pagination['page'] < pagination['totalPages'];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _productService.getCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Product> getProductById(String id) async {
    return await _productService.getProductById(id);
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    loadProducts(refresh: true);
  }

  void setCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    loadProducts(refresh: true);
  }

  void clearFilters() {
    _searchQuery = null;
    _selectedCategoryId = null;
    loadProducts(refresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

