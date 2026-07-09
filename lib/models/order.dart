import '../config.dart';

class Order {
  final int id;
  final String orderNumber;
  final String status;
  final String statusLabel;
  final int totalAmount;
  final int shippingCost;
  final int discountAmount;
  final int pointsDiscount;
  final int grandTotal;
  final String grandTotalFormatted;
  final String? courier;
  final String? courierService;
  final String? trackingNumber;
  final int itemCount;
  final String createdAt;
  // detail only
  final int? pointsEarned;
  final String? paymentMethod;
  final String? paymentMethodLabel;
  final String? paymentProof;
  final String? shippingAddress;
  final String? notes;
  final List<OrderItem>? items;
  final List<Map<String, dynamic>>? returns;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.statusLabel,
    required this.totalAmount,
    required this.shippingCost,
    this.discountAmount = 0,
    this.pointsDiscount = 0,
    required this.grandTotal,
    required this.grandTotalFormatted,
    this.courier,
    this.courierService,
    this.trackingNumber,
    this.itemCount = 0,
    required this.createdAt,
    this.pointsEarned,
    this.paymentMethod,
    this.paymentMethodLabel,
    this.paymentProof,
    this.shippingAddress,
    this.notes,
    this.items,
    this.returns,
  });

  factory Order.fromJson(Map<String, dynamic> json, {bool detail = false}) {
    final itemsList = <OrderItem>[];
    if (json['items'] != null) {
      for (final item in json['items']) {
        itemsList.add(OrderItem.fromJson(item));
      }
    }
    return Order(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String,
      status: json['status'] as String,
      statusLabel: json['status_label'] as String? ?? json['status'] as String,
      totalAmount: json['total_amount'] as int? ?? 0,
      shippingCost: json['shipping_cost'] as int? ?? 0,
      discountAmount: json['discount_amount'] as int? ?? 0,
      pointsDiscount: json['points_discount'] as int? ?? 0,
      grandTotal: json['grand_total'] as int? ?? 0,
      grandTotalFormatted:
          json['grand_total_formatted'] as String? ?? 'Rp 0',
      courier: json['courier'] as String?,
      courierService: json['courier_service'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      itemCount: json['item_count'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      pointsEarned: json['points_earned'] as int?,
      paymentMethod: json['payment_method'] as String?,
      paymentMethodLabel: json['payment_method_label'] as String?,
      paymentProof: AppConfig.imageUrl(json['payment_proof'] as String?),
      shippingAddress: json['shipping_address'] as String?,
      notes: json['notes'] as String?,
      items: detail ? itemsList : null,
      returns: json['returns'] != null
          ? List<Map<String, dynamic>>.from(json['returns'])
          : null,
    );
  }
}

class OrderItem {
  final int id;
  final int productId;
  final String? productName;
  final String? productImage;
  final int price;
  final int quantity;
  final int subtotal;

  OrderItem({
    required this.id,
    required this.productId,
    this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String?,
      productImage: AppConfig.imageUrl(json['product_image'] as String?),
      price: json['price'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      subtotal: json['subtotal'] as int? ?? 0,
    );
  }
}
