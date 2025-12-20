import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../../auth/data/auth_service.dart';

class ProductService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 10,
    String? categoryId,
    String? search,
  }) async {
    final token = await _authService.getToken();
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (categoryId != null) 'category_id': categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.products}')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final products = (data['products'] as List)
          .map((json) => Product.fromJson(json))
          .toList();
      return {
        'products': products,
        'pagination': data['pagination'],
      };
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<List<Category>> getCategories() async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.categories}'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['categories'] as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    final token = await _authService.getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.products}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(productData),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Product.fromJson(data['product']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error']['message'] ?? 'Failed to create product');
    }
  }

  Future<Product> updateProduct(String id, Map<String, dynamic> productData) async {
    final token = await _authService.getToken();

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.products}/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(productData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Product.fromJson(data['product']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error']['message'] ?? 'Failed to update product');
    }
  }

  Future<void> deleteProduct(String id) async {
    final token = await _authService.getToken();

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.products}/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error']['message'] ?? 'Failed to delete product');
    }
  }

  Future<List<Map<String, dynamic>>> searchYoutubeVideos(String query) async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.youtubeSearch}?q=$query&maxResults=10'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['videos']);
    } else {
      throw Exception('Failed to search videos');
    }
  }
}

