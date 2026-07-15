import '../config.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? avatar;
  final String? token;
  final bool? isAdmin;
  final String? createdAt;
  final int? totalSpent;
  final String? totalSpentFormatted;
  final String? membershipTier;
  final int? membershipDiscount;
  final double? pointsMultiplier;
  final String? badgeColor;
  final String? addressType;
  final int? cityId;
  final String? cityName;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.avatar,
    this.token,
    this.isAdmin,
    this.createdAt,
    this.totalSpent,
    this.totalSpentFormatted,
    this.membershipTier,
    this.membershipDiscount,
    this.pointsMultiplier,
    this.badgeColor,
    this.addressType,
    this.cityId,
    this.cityName,
  });

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final tier = customer?['membership_tier'] as Map<String, dynamic>?;

    return User(
      id: _toInt(json['id']),
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      avatar: AppConfig.imageUrl(json['avatar'] as String?),
      token: token,
      isAdmin: json['is_admin'] as bool?,
      createdAt: json['created_at'] as String?,
      totalSpent: customer?['total_spent'] != null ? _toInt(customer!['total_spent']) : null,
      totalSpentFormatted: customer?['total_spent_formatted'] as String?,
      membershipTier: tier?['name'] as String?,
      membershipDiscount: tier?['discount_percent'] != null ? _toInt(tier!['discount_percent']) : null,
      pointsMultiplier: tier?['points_multiplier'] != null ? _toDouble(tier!['points_multiplier']) : null,
      badgeColor: tier?['badge_color'] as String?,
      addressType: customer?['address_type'] as String?,
      cityId: customer?['city_id'] != null ? _toInt(customer!['city_id']) : null,
      cityName: customer?['city_name'] as String?,
    );
  }
}
