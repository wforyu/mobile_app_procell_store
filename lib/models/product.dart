import '../config.dart';

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
  final bool isFlashSale;
  final String? flashSaleStart;
  final String? flashSaleEnd;
  final bool isFlashSaleActive;

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
    this.isFlashSale = false,
    this.flashSaleStart,
    this.flashSaleEnd,
    this.isFlashSaleActive = false,
  });

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    int originalPrice = _toInt(json['price']);
    return Product(
      id: _toInt(json['id']),
      name: json['name'] as String,
      slug: json['slug'] as String,
      brand: json['brand'] as String?,
      price: originalPrice,
      priceFormatted: json['price_formatted'] as String? ??
          'Rp ${_formatNumber(originalPrice)}',
      promoPrice: json['promo_price'] != null ? _toInt(json['promo_price']) : null,
      promoPriceFormatted: json['promo_price_formatted'] as String?,
      hasDiscount: json['has_discount'] as bool? ?? false,
      discountPercent: json['discount_percent'] != null ? _toInt(json['discount_percent']) : null,
      stock: _toInt(json['stock']),
      image: AppConfig.imageUrl(json['image'] as String?),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: _toInt(json['review_count']),
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      weight: json['weight'] != null ? _toInt(json['weight']) : null,
      images: json['images'] != null
          ? (json['images'] as List).map((img) {
              final m = Map<String, dynamic>.from(img);
              if (m['url'] != null) {
                m['url'] = AppConfig.imageUrl(m['url']);
              }
              return m;
            }).toList()
          : null,
      reviews: json['reviews'] != null
          ? List<Map<String, dynamic>>.from(json['reviews'])
          : null,
      category: json['category'] != null
          ? CategoryInfo.fromJson(json['category'])
          : null,
      isFlashSale: json['is_flash_sale'] as bool? ?? false,
      flashSaleStart: json['flash_sale_start'] as String?,
      flashSaleEnd: json['flash_sale_end'] as String?,
      isFlashSaleActive: json['is_flash_sale_active'] as bool? ?? false,
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
      id: Product._toInt(json['id']),
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }
}
