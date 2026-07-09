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

  factory Cart.fromJson(Map<String, dynamic> json) {
    final itemsList = <CartItem>[];
    if (json['items'] != null) {
      for (final item in json['items']) {
        itemsList.add(CartItem.fromJson(item));
      }
    }
    return Cart(
      id: json['id'] as int,
      items: itemsList,
      total: json['total'] as int? ?? 0,
      totalFormatted: json['total_formatted'] as String? ?? 'Rp 0',
      count: json['count'] as int? ?? 0,
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

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      product: json['product'] != null
          ? CartProduct.fromJson(json['product'])
          : null,
      quantity: json['quantity'] as int? ?? 0,
      price: json['price'] as int? ?? 0,
      subtotal: json['subtotal'] as int? ?? 0,
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

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      price: json['price'] as int? ?? 0,
      priceFormatted: json['price_formatted'] as String? ?? 'Rp 0',
      promoPrice: json['promo_price'] as int?,
      promoPriceFormatted: json['promo_price_formatted'] as String?,
      image: AppConfig.imageUrl(json['image'] as String?),
      stock: json['stock'] as int? ?? 0,
    );
  }
}
