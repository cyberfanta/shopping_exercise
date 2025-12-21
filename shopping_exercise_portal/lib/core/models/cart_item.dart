class CartItem {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;
  final String? youtubeThumbnail;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.youtubeThumbnail,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? 'Sin nombre',
      price: _parseDouble(json['price']) ?? 0.0,
      quantity: _parseInt(json['quantity']) ?? 0,
      subtotal: _parseDouble(json['subtotal']) ?? 0.0,
      youtubeThumbnail: json['youtube_thumbnail'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
      'youtube_thumbnail': youtubeThumbnail,
    };
  }
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

