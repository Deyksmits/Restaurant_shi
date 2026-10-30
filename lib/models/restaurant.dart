import 'menu_item.dart';

class Restaurant {
  final String id;
  final String name;
  final String tagline;
  final String address;
  final String city;
  final String neighborhood;
  final double latitude;
  final double longitude;
  final List<String> photoUrls;
  final double rating;
  final int reviewCount;
  final String priceTier; // "€", "€€", "€€€", "€€€€"
  final List<String> categories; // e.g. "Dutch Eetcafé", "Borrel", "Indonesian", "Italian"
  final List<String> dietaryTags; // "Vegetarian-friendly", "Halal Options", "Vegan", "Gluten-free"
  final List<MenuItem> menuItems;
  final String openingHours;
  final bool isSponsored;
  final String? sponsoredNote;
  final String phoneNumber;
  final String websiteUrl;

  const Restaurant({
    required this.id,
    required this.name,
    required this.tagline,
    required this.address,
    required this.city,
    required this.neighborhood,
    required this.latitude,
    required this.longitude,
    required this.photoUrls,
    required this.rating,
    required this.reviewCount,
    required this.priceTier,
    required this.categories,
    required this.dietaryTags,
    required this.menuItems,
    required this.openingHours,
    this.isSponsored = false,
    this.sponsoredNote,
    required this.phoneNumber,
    required this.websiteUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'address': address,
      'city': city,
      'neighborhood': neighborhood,
      'latitude': latitude,
      'longitude': longitude,
      'photoUrls': photoUrls,
      'rating': rating,
      'reviewCount': reviewCount,
      'priceTier': priceTier,
      'categories': categories,
      'dietaryTags': dietaryTags,
      'menuItems': menuItems.map((item) => item.toJson()).toList(),
      'openingHours': openingHours,
      'isSponsored': isSponsored,
      'sponsoredNote': sponsoredNote,
      'phoneNumber': phoneNumber,
      'websiteUrl': websiteUrl,
    };
  }

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      tagline: json['tagline'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      neighborhood: json['neighborhood'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      photoUrls: List<String>.from(json['photoUrls'] as List),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      priceTier: json['priceTier'] as String,
      categories: List<String>.from(json['categories'] as List),
      dietaryTags: List<String>.from(json['dietaryTags'] as List),
      menuItems: (json['menuItems'] as List)
          .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      openingHours: json['openingHours'] as String,
      isSponsored: json['isSponsored'] as bool? ?? false,
      sponsoredNote: json['sponsoredNote'] as String?,
      phoneNumber: json['phoneNumber'] as String,
      websiteUrl: json['websiteUrl'] as String,
    );
  }
}
