import '../config.dart';

class Cart {
  final int id;
  final List<CartItem> items;
  final int total;
  final String totalFormatted;
  final int count;

  Cart({
    required this.id,
    required this.items,
    required this.total,
    required this.totalFormatted,
    required this.count,
  });

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    final itemsList = <CartItem>[];
    if (json['items'] != null) {
      for (final item in json['items']) {
        itemsList.add(CartItem.fromJson(item));
      }
    }
    return Cart(
      id: _toInt(json['id']),
      items: itemsList,
      total: _toInt(json['total']),
      totalFormatted: json['total_formatted'] as String? ?? 'Rp 0',
      count: _toInt(json['count']),
    );
  }
}

class CartItem {
  final int id;
  final int productId;
  final CartProduct? product;
  final int quantity;
  final int price;
  final int subtotal;
  final String subtotalFormatted;

  CartItem({
    required this.id,
    required this.productId,
    this.product,
    required this.quantity,
    required this.price,
    required this.subtotal,
    required this.subtotalFormatted,
  });

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: _toInt(json['id']),
      productId: _toInt(json['product_id']),
      product: json['product'] != null
          ? CartProduct.fromJson(json['product'])
          : null,
      quantity: _toInt(json['quantity']),
      price: _toInt(json['price']),
      subtotal: _toInt(json['subtotal']),
      subtotalFormatted:
          json['subtotal_formatted'] as String? ?? 'Rp 0',
    );
  }
}

class CartProduct {
  final int id;
  final String name;
  final String slug;
  final int price;
  final String priceFormatted;
  final int? promoPrice;
  final String? promoPriceFormatted;
  final String? image;
  final int stock;

  CartProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.priceFormatted,
    this.promoPrice,
    this.promoPriceFormatted,
    this.image,
    required this.stock,
  });

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      id: _toInt(json['id']),
      name: json['name'] as String,
      slug: json['slug'] as String,
      price: _toInt(json['price']),
      priceFormatted: json['price_formatted'] as String? ?? 'Rp 0',
      promoPrice: json['promo_price'] != null ? _toInt(json['promo_price']) : null,
      promoPriceFormatted: json['promo_price_formatted'] as String?,
      image: AppConfig.imageUrl(json['image'] as String?),
      stock: _toInt(json['stock']),
    );
  }
}
