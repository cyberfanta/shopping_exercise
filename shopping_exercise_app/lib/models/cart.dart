import 'product.dart';

class CartItem {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;
  final String? youtubeThumbnail;
  Product? product;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.youtubeThumbnail,
    this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      price: (json['price'] is String)
          ? double.parse(json['price'] as String)
          : (json['price'] as num).toDouble(),
      quantity: json['quantity'] is String
          ? int.parse(json['quantity'] as String)
          : json['quantity'] as int,
      subtotal: (json['subtotal'] is String)
          ? double.parse(json['subtotal'] as String)
          : (json['subtotal'] as num).toDouble(),
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

class Cart {
  final String id;
  final List<CartItem> items;
  final double subtotal;

  Cart({
    required this.id,
    required this.items,
    required this.subtotal,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    // El backend puede devolver 'total' o 'subtotal'
    final totalValue = json['total'] ?? json['subtotal'];
    
    return Cart(
      id: json['id'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: totalValue != null
          ? (totalValue is String
              ? double.parse(totalValue)
              : (totalValue as num).toDouble())
          : 0.0,
    );
  }

  int get itemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);
}

