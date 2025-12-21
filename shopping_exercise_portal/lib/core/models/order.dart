class Order {
  final String id;
  final String orderNumber;
  final String status;
  final String? paymentStatus;
  final String? paymentMethod;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final int itemsCount;
  final DateTime createdAt;
  final String? userEmail;
  final String? userFirstName;
  final String? userLastName;
  final List<OrderItem>? items;
  final Map<String, dynamic>? shippingAddress;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.paymentStatus,
    this.paymentMethod,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.itemsCount,
    required this.createdAt,
    this.userEmail,
    this.userFirstName,
    this.userLastName,
    this.items,
    this.shippingAddress,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['payment_status'] as String?,
      paymentMethod: json['payment_method'] as String?,
      subtotal: _parseDouble(json['subtotal']) ?? 0.0,
      tax: _parseDouble(json['tax']) ?? 0.0,
      shipping: _parseDouble(json['shipping']) ?? 0.0,
      total: _parseDouble(json['total']) ?? 0.0,
      itemsCount: _parseInt(json['items_count']) ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      userEmail: json['user_email'] as String?,
      userFirstName: json['user_first_name'] as String?,
      userLastName: json['user_last_name'] as String?,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList()
          : null,
      shippingAddress: json['shipping_address'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'status': status,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shipping,
      'total': total,
      'items_count': itemsCount,
      'created_at': createdAt.toIso8601String(),
      'user_email': userEmail,
      'user_first_name': userFirstName,
      'user_last_name': userLastName,
      'items': items?.map((item) => item.toJson()).toList(),
      'shipping_address': shippingAddress,
    };
  }

  String get userName {
    if (userFirstName != null || userLastName != null) {
      return '${userFirstName ?? ''} ${userLastName ?? ''}'.trim();
    }
    return userEmail ?? 'Usuario desconocido';
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmado';
      case 'processing':
        return 'En proceso';
      case 'shipped':
        return 'Enviado';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String? productDescription;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productDescription,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? 'Sin nombre',
      productDescription: json['product_description'] as String?,
      quantity: _parseInt(json['quantity']) ?? 0,
      unitPrice: _parseDouble(json['unit_price']) ?? 0.0,
      subtotal: _parseDouble(json['subtotal']) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_description': productDescription,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
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

