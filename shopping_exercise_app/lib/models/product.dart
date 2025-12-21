class Product {
  final String id;
  final String categoryId;
  final String? categoryName;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final int stock;
  final String? youtubeVideoId;
  final String? youtubeChannelId;
  final String? youtubeThumbnail;
  final String? youtubeDuration;
  final bool isActive;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.categoryId,
    this.categoryName,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.stock,
    this.youtubeVideoId,
    this.youtubeChannelId,
    this.youtubeThumbnail,
    this.youtubeDuration,
    required this.isActive,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String?,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] is String)
          ? double.parse(json['price'] as String)
          : (json['price'] as num).toDouble(),
      discountPrice: json['discount_price'] != null
          ? (json['discount_price'] is String
              ? double.parse(json['discount_price'] as String)
              : (json['discount_price'] as num).toDouble())
          : null,
      stock: json['stock'] as int,
      youtubeVideoId: json['youtube_video_id'] as String?,
      youtubeChannelId: json['youtube_channel_id'] as String?,
      youtubeThumbnail: json['youtube_thumbnail'] as String?,
      youtubeDuration: json['youtube_duration'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'category_name': categoryName,
      'name': name,
      'description': description,
      'price': price,
      'discount_price': discountPrice,
      'stock': stock,
      'youtube_video_id': youtubeVideoId,
      'youtube_channel_id': youtubeChannelId,
      'youtube_thumbnail': youtubeThumbnail,
      'youtube_duration': youtubeDuration,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  double get effectivePrice => discountPrice ?? price;

  String get displayDuration {
    if (youtubeDuration == null) return '';
    
    // Parse ISO 8601 duration format (PT15M30S)
    final match = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?')
        .firstMatch(youtubeDuration!);
    
    if (match == null) return '';
    
    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

