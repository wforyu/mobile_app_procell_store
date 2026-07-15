import '../config.dart';

class BannerModel {
  final int id;
  final String? title;
  final String? link;
  final String? image;
  final String? type;
  final int sortOrder;

  BannerModel({
    required this.id,
    this.title,
    this.link,
    this.image,
    this.type,
    this.sortOrder = 0,
  });

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: _toInt(json['id']),
      title: json['title'] as String?,
      link: json['link'] as String?,
      image: AppConfig.imageUrl(json['image'] as String?),
      type: json['type'] as String?,
      sortOrder: _toInt(json['sort_order']),
    );
  }
}
