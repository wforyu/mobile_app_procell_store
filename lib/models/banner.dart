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

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as int,
      title: json['title'] as String?,
      link: json['link'] as String?,
      image: AppConfig.imageUrl(json['image'] as String?),
      type: json['type'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
