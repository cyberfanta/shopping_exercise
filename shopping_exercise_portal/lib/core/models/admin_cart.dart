class AdminCart {
  final String cartId;
  final String userId;
  final String userEmail;
  final String? firstName;
  final String? lastName;
  final int itemsCount;
  final double subtotal;
  final DateTime updatedAt;
  final List<AdminCartItem> items;

  AdminCart({
    required this.cartId,
    required this.userId,
    required this.userEmail,
    this.firstName,
    this.lastName,
    required this.itemsCount,
    required this.subtotal,
    required this.updatedAt,
    required this.items,
  });

  factory AdminCart.fromJson(Map<String, dynamic> json) {
    return AdminCart(
      cartId: json['cart_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userEmail: json['user_email'] as String? ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      itemsCount: _parseInt(json['items_count']) ?? 0,
      subtotal: _parseDouble(json['subtotal']) ?? 0.0,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => AdminCartItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get userName {
    if (firstName != null || lastName != null) {
      return '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }
    return 'Sin nombre';
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class AdminCartItem {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;
  final String? youtubeThumbnail;

  AdminCartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.youtubeThumbnail,
  });

  factory AdminCartItem.fromJson(Map<String, dynamic> json) {
    return AdminCartItem(
      id: json['id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? 'Sin nombre',
      price: _parseDouble(json['price']),
      quantity: _parseInt(json['quantity']),
      subtotal: _parseDouble(json['subtotal']),
      youtubeThumbnail: json['youtube_thumbnail'] as String?,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

