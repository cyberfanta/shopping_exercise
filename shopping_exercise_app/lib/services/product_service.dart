import '../models/product.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class ProductService {
  final ApiService _api;

  ProductService(this._api);

  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 10,
    String? categoryId,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (categoryId != null) {
      queryParams['category_id'] = categoryId;
    }

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _api.get(
      ApiConfig.products,
      queryParams: queryParams,
    );

    final products = (response['products'] as List<dynamic>)
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();

    return {
      'products': products,
      'pagination': response['pagination'],
    };
  }

  Future<Product> getProductById(String id) async {
    final response = await _api.get('${ApiConfig.products}/$id');
    return Product.fromJson(response['product'] as Map<String, dynamic>);
  }

  Future<List<Category>> getCategories({
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _api.get(
      ApiConfig.categories,
      queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    return (response['categories'] as List<dynamic>)
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

