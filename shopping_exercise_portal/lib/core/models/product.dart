class Product {
  final String id;
  final String? categoryId;
  final String? categoryName;
  final String name;
  final String? description;
  final double price;
  final double? discountPrice;
  final int stock;
  final String? youtubeVideoId;
  final String? youtubeChannelId;
  final String? youtubeThumbnail;
  final String? youtubeDuration;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;

  Product({
    required this.id,
    this.categoryId,
    this.categoryName,
    required this.name,
    this.description,
    required this.price,
    this.discountPrice,
    required this.stock,
    this.youtubeVideoId,
    this.youtubeChannelId,
    this.youtubeThumbnail,
    this.youtubeDuration,
    this.imageUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      name: json['name'] as String? ?? 'Sin nombre',
      description: json['description'] as String?,
      price: _parseDouble(json['price']) ?? 0.0,
      discountPrice: json['discount_price'] != null 
          ? _parseDouble(json['discount_price'])
          : null,
      stock: _parseInt(json['stock']) ?? 0,
      youtubeVideoId: json['youtube_video_id'] as String?,
      youtubeChannelId: json['youtube_channel_id'] as String?,
      youtubeThumbnail: json['youtube_thumbnail'] as String?,
      youtubeDuration: json['youtube_duration'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'discount_price': discountPrice,
      'stock': stock,
      'youtube_video_id': youtubeVideoId,
      'youtube_channel_id': youtubeChannelId,
      'youtube_thumbnail': youtubeThumbnail,
      'youtube_duration': youtubeDuration,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }

  String get thumbnail => youtubeThumbnail ?? imageUrl ?? '';
  double get finalPrice => discountPrice ?? price;
}

