import '../config.dart';

class Category {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? image;
  final int productCount;
  final int sortOrder;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.image,
    this.productCount = 0,
    this.sortOrder = 0,
  });

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: _toInt(json['id']),
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      image: AppConfig.imageUrl(json['image'] as String?),
      productCount: _toInt(json['product_count']),
      sortOrder: _toInt(json['sort_order']),
    );
  }
}
