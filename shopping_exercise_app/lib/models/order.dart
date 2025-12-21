class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String? productDescription;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? youtubeThumbnail;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productDescription,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.youtubeThumbnail,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productDescription: json['product_description'] as String?,
      quantity: json['quantity'] is String
          ? int.parse(json['quantity'] as String)
          : json['quantity'] as int,
      unitPrice: (json['unit_price'] is String)
          ? double.parse(json['unit_price'] as String)
          : (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] is String)
          ? double.parse(json['subtotal'] as String)
          : (json['subtotal'] as num).toDouble(),
      youtubeThumbnail: json['youtube_thumbnail'] as String?,
    );
  }
}

class ShippingAddress {
  final String street;
  final String city;
  final String state;
  final String zip;
  final String country;

  ShippingAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      street: json['street'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zip: json['zip'] ?? json['zipCode'] as String,
      country: json['country'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zip': zip,
      'country': country,
    };
  }

  String get fullAddress => '$street, $city, $state $zip, $country';
}

class Order {
  final String id;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final String paymentStatus;
  final String? paymentMethod;
  final ShippingAddress? shippingAddress;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OrderItem>? items;
  final int? itemsCount;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.paymentStatus,
    this.paymentMethod,
    this.shippingAddress,
    required this.createdAt,
    this.updatedAt,
    this.items,
    this.itemsCount,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      status: json['status'] as String,
      subtotal: (json['subtotal'] is String)
          ? double.parse(json['subtotal'] as String)
          : (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] is String)
          ? double.parse(json['tax'] as String)
          : (json['tax'] as num).toDouble(),
      shipping: (json['shipping'] is String)
          ? double.parse(json['shipping'] as String)
          : (json['shipping'] as num).toDouble(),
      total: (json['total'] is String)
          ? double.parse(json['total'] as String)
          : (json['total'] as num).toDouble(),
      paymentStatus: json['payment_status'] as String,
      paymentMethod: json['payment_method'] as String?,
      shippingAddress: json['shipping_address'] != null
          ? ShippingAddress.fromJson(
              json['shipping_address'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      items: json['items'] != null
          ? (json['items'] as List<dynamic>)
              .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      itemsCount: json['items_count'] != null
          ? (json['items_count'] is String
              ? int.parse(json['items_count'] as String)
              : json['items_count'] as int)
          : null,
    );
  }

  String get statusDisplay {
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

  String get paymentStatusDisplay {
    switch (paymentStatus) {
      case 'pending':
        return 'Pendiente';
      case 'paid':
        return 'Pagado';
      case 'failed':
        return 'Fallido';
      case 'refunded':
        return 'Reembolsado';
      default:
        return paymentStatus;
    }
  }
}

