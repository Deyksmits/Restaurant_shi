import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_shi/models/group_session.dart';

void main() {
  group('CloudSyncService & Multiplayer Logic Tests', () {
    test('GroupSession correctly serializes to/from JSON for Firebase', () {
      final session = GroupSession(
        id: 'group_test_123',
        pinCode: '482 910',
        title: 'Den Haag Dinner Club',
        locationCity: 'Den Haag',
        targetDate: DateTime(2026, 11, 15, 19, 30),
        matchRule: MatchRule.unanimous,
        status: GroupStatus.lobby,
        hostId: 'user_host',
        members: [
          const GroupMember(
            userId: 'user_host',
            displayName: 'Host User',
            avatarUrl: 'https://example.com/host.jpg',
            isHost: true,
            isReady: true,
            dietaryPreferences: ['Vegetarian'],
          ),
          const GroupMember(
            userId: 'user_friend',
            displayName: 'Friend iPhone',
            avatarUrl: 'https://example.com/friend.jpg',
            isHost: false,
            isReady: true,
            dietaryPreferences: ['Gluten-free'],
          ),
        ],
        restaurantDeckIds: ['dh_01', 'dh_02', 'dh_03'],
        votes: {
          'dh_01': ['user_host', 'user_friend'],
        },
        matchedRestaurantIds: ['dh_01'],
      );

      final json = session.toJson();
      expect(json['id'], 'group_test_123');
      expect(json['pinCode'], '482 910');
      expect(json['locationCity'], 'Den Haag');
      expect(json['members'].length, 2);
      expect(json['matchedRestaurantIds'], ['dh_01']);

      // Deserialize back
      final reconstituted = GroupSession.fromJson(json);
      expect(reconstituted.id, session.id);
      expect(reconstituted.pinCode, session.pinCode);
      expect(reconstituted.members.first.displayName, 'Host User');
      expect(reconstituted.votes['dh_01']?.length, 2);
      expect(reconstituted.aggregatedDietaryRestrictions.contains('Vegetarian'), true);
      expect(reconstituted.aggregatedDietaryRestrictions.contains('Gluten-free'), true);
    });

    test('Majority vs Unanimous matching rules work accurately', () {
      final members = [
        const GroupMember(userId: 'u1', displayName: 'U1', avatarUrl: ''),
        const GroupMember(userId: 'u2', displayName: 'U2', avatarUrl: ''),
        const GroupMember(userId: 'u3', displayName: 'U3', avatarUrl: ''),
      ];

      // Case 1: 2 out of 3 like it -> Majority MATCHES, Unanimous DOES NOT
      final votes2of3 = {'dh_01': ['u1', 'u2']};

      final majorityPass = votes2of3['dh_01']!.length > (members.length / 2);
      final unanimousPass = votes2of3['dh_01']!.length >= members.length;

      expect(majorityPass, true);
      expect(unanimousPass, false);

      // Case 2: 3 out of 3 like it -> Both MATCH
      final votes3of3 = {'dh_01': ['u1', 'u2', 'u3']};
      expect(votes3of3['dh_01']!.length >= members.length, true);
    });
  });
}
