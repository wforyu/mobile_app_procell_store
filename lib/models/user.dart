class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? avatar;
  final String? token;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.avatar,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      avatar: json['avatar'] as String?,
      token: token,
    );
  }
}
