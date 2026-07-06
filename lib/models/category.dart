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

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      image: json['image'] as String?,
      productCount: json['product_count'] as int? ?? 0,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
