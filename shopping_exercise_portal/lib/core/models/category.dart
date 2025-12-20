class Category {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Sin nombre',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }
}

