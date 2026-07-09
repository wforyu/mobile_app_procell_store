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
  final int? pointsMultiplier;
  final String? badgeColor;

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
  });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final tier = customer?['membership_tier'] as Map<String, dynamic>?;

    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      avatar: AppConfig.imageUrl(json['avatar'] as String?),
      token: token,
      isAdmin: json['is_admin'] as bool?,
      createdAt: json['created_at'] as String?,
      totalSpent: customer?['total_spent'] as int?,
      totalSpentFormatted: customer?['total_spent_formatted'] as String?,
      membershipTier: tier?['name'] as String?,
      membershipDiscount: tier?['discount_percent'] as int?,
      pointsMultiplier: tier?['points_multiplier'] as int?,
      badgeColor: tier?['badge_color'] as String?,
    );
  }
}
