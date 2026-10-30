enum MatchRule { unanimous, majority }
enum GroupStatus { lobby, swiping, completed }

class GroupMember {
  final String userId;
  final String displayName;
  final String avatarUrl;
  final bool isHost;
  final bool isReady;
  final bool hasFinished;
  final List<String> dietaryPreferences;

  const GroupMember({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    this.isHost = false,
    this.isReady = false,
    this.hasFinished = false,
    this.dietaryPreferences = const [],
  });

  GroupMember copyWith({
    bool? isReady,
    bool? hasFinished,
  }) {
    return GroupMember(
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      isHost: isHost,
      isReady: isReady ?? this.isReady,
      hasFinished: hasFinished ?? this.hasFinished,
      dietaryPreferences: dietaryPreferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'isHost': isHost,
      'isReady': isReady,
      'hasFinished': hasFinished,
      'dietaryPreferences': dietaryPreferences,
    };
  }

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String,
      isHost: json['isHost'] as bool? ?? false,
      isReady: json['isReady'] as bool? ?? false,
      hasFinished: json['hasFinished'] as bool? ?? false,
      dietaryPreferences: List<String>.from(json['dietaryPreferences'] ?? []),
    );
  }
}

class GroupSession {
  final String id;
  final String pinCode; // 6-digit Kahoot-style room code, e.g. "839 210"
  final String title; // e.g. "Friday Drinks & Bites"
  final String locationCity; // e.g. "Amsterdam"
  final DateTime targetDate;
  final MatchRule matchRule;
  final GroupStatus status;
  final String hostId;
  final List<GroupMember> members;
  final List<String> restaurantDeckIds;
  // restaurantId -> list of userIds who swiped right (liked)
  final Map<String, List<String>> votes;
  final List<String> matchedRestaurantIds;

  const GroupSession({
    required this.id,
    required this.pinCode,
    required this.title,
    required this.locationCity,
    required this.targetDate,
    required this.matchRule,
    required this.status,
    required this.hostId,
    required this.members,
    required this.restaurantDeckIds,
    this.votes = const {},
    this.matchedRestaurantIds = const [],
  });

  GroupSession copyWith({
    GroupStatus? status,
    List<GroupMember>? members,
    List<String>? restaurantDeckIds,
    Map<String, List<String>>? votes,
    List<String>? matchedRestaurantIds,
  }) {
    return GroupSession(
      id: id,
      pinCode: pinCode,
      title: title,
      locationCity: locationCity,
      targetDate: targetDate,
      matchRule: matchRule,
      status: status ?? this.status,
      hostId: hostId,
      members: members ?? this.members,
      restaurantDeckIds: restaurantDeckIds ?? this.restaurantDeckIds,
      votes: votes ?? this.votes,
      matchedRestaurantIds: matchedRestaurantIds ?? this.matchedRestaurantIds,
    );
  }

  /// Aggregated dietary requirements of all participants who joined
  Set<String> get aggregatedDietaryRestrictions {
    final restrictions = <String>{};
    for (final member in members) {
      restrictions.addAll(member.dietaryPreferences);
    }
    return restrictions;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pinCode': pinCode,
      'title': title,
      'locationCity': locationCity,
      'targetDate': targetDate.toIso8601String(),
      'matchRule': matchRule.name,
      'status': status.name,
      'hostId': hostId,
      'members': members.map((m) => m.toJson()).toList(),
      'restaurantDeckIds': restaurantDeckIds,
      'votes': votes,
      'matchedRestaurantIds': matchedRestaurantIds,
    };
  }

  factory GroupSession.fromJson(Map<String, dynamic> json) {
    return GroupSession(
      id: json['id'] as String,
      pinCode: json['pinCode'] as String,
      title: json['title'] as String,
      locationCity: json['locationCity'] as String,
      targetDate: DateTime.parse(json['targetDate'] as String),
      matchRule: MatchRule.values.firstWhere(
        (e) => e.name == json['matchRule'],
        orElse: () => MatchRule.unanimous,
      ),
      status: GroupStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GroupStatus.lobby,
      ),
      hostId: json['hostId'] as String,
      members: (json['members'] as List)
          .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      restaurantDeckIds: List<String>.from(json['restaurantDeckIds'] ?? []),
      votes: (json['votes'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, List<String>.from(v as List)),
      ),
      matchedRestaurantIds: List<String>.from(json['matchedRestaurantIds'] ?? []),
    );
  }
}
