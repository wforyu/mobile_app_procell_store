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
  final String? recipientName;
  final String? recipientPhone;
  final String? notes;
  final List<OrderItem>? items;
  final List<Map<String, dynamic>>? returns;
  final String? trackingUrl;
  final List<Map<String, dynamic>>? trackingTimeline;

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
    this.recipientName,
    this.recipientPhone,
    this.notes,
    this.items,
    this.returns,
    this.trackingUrl,
    this.trackingTimeline,
  });

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory Order.fromJson(Map<String, dynamic> json, {bool detail = false}) {
    final itemsList = <OrderItem>[];
    if (json['items'] != null) {
      for (final item in json['items']) {
        itemsList.add(OrderItem.fromJson(item));
      }
    }
    return Order(
      id: _toInt(json['id']),
      orderNumber: json['order_number'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? (json['status'] as String? ?? ''),
      totalAmount: _toInt(json['total_amount']),
      shippingCost: _toInt(json['shipping_cost']),
      discountAmount: _toInt(json['discount_amount']),
      pointsDiscount: _toInt(json['points_discount']),
      grandTotal: _toInt(json['grand_total']),
      grandTotalFormatted:
          json['grand_total_formatted'] as String? ?? 'Rp 0',
      courier: json['courier'] as String?,
      courierService: json['courier_service'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      itemCount: _toInt(json['item_count']),
      createdAt: json['created_at'] as String? ?? '',
      pointsEarned: json['points_earned'] != null ? _toInt(json['points_earned']) : null,
      paymentMethod: json['payment_method'] as String?,
      paymentMethodLabel: json['payment_method_label'] as String?,
      paymentProof: AppConfig.imageUrl(json['payment_proof'] as String?),
      shippingAddress: json['shipping_address'] as String?,
      recipientName: json['recipient_name'] as String?,
      recipientPhone: json['recipient_phone'] as String?,
      notes: json['notes'] as String?,
      items: detail ? itemsList : null,
      returns: json['returns'] != null
          ? List<Map<String, dynamic>>.from(json['returns'])
          : null,
      trackingUrl: json['tracking_url'] as String?,
      trackingTimeline: json['tracking_timeline'] != null
          ? List<Map<String, dynamic>>.from(json['tracking_timeline'])
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
      id: Order._toInt(json['id']),
      productId: Order._toInt(json['product_id']),
      productName: json['product_name'] as String?,
      productImage: AppConfig.imageUrl(json['product_image'] as String?),
      price: Order._toInt(json['price']),
      quantity: Order._toInt(json['quantity']),
      subtotal: Order._toInt(json['subtotal']),
    );
  }
}
