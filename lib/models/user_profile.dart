enum SwipeType { like, dislike, superlike }

class UserProfile {
  final String id;
  final String displayName;
  final String? email;
  final String? phoneNumber;
  final String avatarUrl;
  final String friendCode; // e.g. "FOODIE-8842"
  final bool isGuest;
  final List<String> dietaryPreferences; // e.g. "Vegetarian", "Vegan", "Halal", "Gluten-free"
  final List<String> favoriteIds;
  final List<String> superLikeIds;
  final List<String> friendIds;
  final List<String> incomingFriendRequests;
  final Map<String, String> swipeHistory; // restaurantId -> "like" | "dislike" | "superlike"

  const UserProfile({
    required this.id,
    required this.displayName,
    this.email,
    this.phoneNumber,
    required this.avatarUrl,
    required this.friendCode,
    this.isGuest = false,
    this.dietaryPreferences = const [],
    this.favoriteIds = const [],
    this.superLikeIds = const [],
    this.friendIds = const [],
    this.incomingFriendRequests = const [],
    this.swipeHistory = const {},
  });

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    bool? isGuest,
    List<String>? dietaryPreferences,
    List<String>? favoriteIds,
    List<String>? superLikeIds,
    List<String>? friendIds,
    List<String>? incomingFriendRequests,
    Map<String, String>? swipeHistory,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      friendCode: friendCode,
      isGuest: isGuest ?? this.isGuest,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      superLikeIds: superLikeIds ?? this.superLikeIds,
      friendIds: friendIds ?? this.friendIds,
      incomingFriendRequests: incomingFriendRequests ?? this.incomingFriendRequests,
      swipeHistory: swipeHistory ?? this.swipeHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'friendCode': friendCode,
      'isGuest': isGuest,
      'dietaryPreferences': dietaryPreferences,
      'favoriteIds': favoriteIds,
      'superLikeIds': superLikeIds,
      'friendIds': friendIds,
      'incomingFriendRequests': incomingFriendRequests,
      'swipeHistory': swipeHistory,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String,
      friendCode: json['friendCode'] as String,
      isGuest: json['isGuest'] as bool? ?? false,
      dietaryPreferences: List<String>.from(json['dietaryPreferences'] ?? []),
      favoriteIds: List<String>.from(json['favoriteIds'] ?? []),
      superLikeIds: List<String>.from(json['superLikeIds'] ?? []),
      friendIds: List<String>.from(json['friendIds'] ?? []),
      incomingFriendRequests: List<String>.from(json['incomingFriendRequests'] ?? []),
      swipeHistory: Map<String, String>.from(json['swipeHistory'] ?? {}),
    );
  }
}
