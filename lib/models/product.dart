class Product {
  final int id;
  final String name;
  final String slug;
  final String? brand;
  final int price;
  final String priceFormatted;
  final int? promoPrice;
  final String? promoPriceFormatted;
  final bool hasDiscount;
  final int? discountPercent;
  final int stock;
  final String? image;
  final double rating;
  final int reviewCount;
  final String? description;
  final String? sku;
  final int? weight;
  final List<Map<String, dynamic>>? images;
  final List<Map<String, dynamic>>? reviews;
  final CategoryInfo? category;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    this.brand,
    required this.price,
    required this.priceFormatted,
    this.promoPrice,
    this.promoPriceFormatted,
    this.hasDiscount = false,
    this.discountPercent,
    required this.stock,
    this.image,
    this.rating = 0,
    this.reviewCount = 0,
    this.description,
    this.sku,
    this.weight,
    this.images,
    this.reviews,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    int originalPrice = json['price'] as int;
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      brand: json['brand'] as String?,
      price: originalPrice,
      priceFormatted: json['price_formatted'] as String? ??
          'Rp ${_formatNumber(originalPrice)}',
      promoPrice: json['promo_price'] as int?,
      promoPriceFormatted: json['promo_price_formatted'] as String?,
      hasDiscount: json['has_discount'] as bool? ?? false,
      discountPercent: json['discount_percent'] as int?,
      stock: json['stock'] as int? ?? 0,
      image: json['image'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      weight: json['weight'] as int?,
      images: json['images'] != null
          ? List<Map<String, dynamic>>.from(json['images'])
          : null,
      reviews: json['reviews'] != null
          ? List<Map<String, dynamic>>.from(json['reviews'])
          : null,
      category: json['category'] != null
          ? CategoryInfo.fromJson(json['category'])
          : null,
    );
  }

  int get effectivePrice => promoPrice ?? price;

  String get effectivePriceFormatted =>
      promoPriceFormatted ?? priceFormatted;

  static String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}

class CategoryInfo {
  final int id;
  final String name;
  final String slug;

  CategoryInfo({required this.id, required this.name, required this.slug});

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }
}
