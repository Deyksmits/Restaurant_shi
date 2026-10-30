enum NewsType { appUpdate, newRestaurant, friendActivity, promotion }

class NewsItem {
  final String id;
  final String title;
  final String subtitle;
  final String content;
  final String imageUrl;
  final DateTime publishedAt;
  final NewsType type;
  final String badgeText;
  final String? relatedRestaurantId;

  const NewsItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.imageUrl,
    required this.publishedAt,
    required this.type,
    required this.badgeText,
    this.relatedRestaurantId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'content': content,
      'imageUrl': imageUrl,
      'publishedAt': publishedAt.toIso8601String(),
      'type': type.name,
      'badgeText': badgeText,
      'relatedRestaurantId': relatedRestaurantId,
    };
  }

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      type: NewsType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NewsType.appUpdate,
      ),
      badgeText: json['badgeText'] as String,
      relatedRestaurantId: json['relatedRestaurantId'] as String?,
    );
  }
}
