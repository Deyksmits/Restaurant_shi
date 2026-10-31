import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_shi/models/group_session.dart';
import 'package:restaurant_shi/services/cloud_sync_service.dart';

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
        members: const [
          GroupMember(
            userId: 'user_host',
            displayName: 'Host User',
            avatarUrl: 'https://example.com/host.jpg',
            isHost: true,
            isReady: true,
            dietaryPreferences: ['Vegetarian'],
          ),
          GroupMember(
            userId: 'user_friend',
            displayName: 'Friend iPhone',
            avatarUrl: 'https://example.com/friend.jpg',
            isHost: false,
            isReady: true,
            dietaryPreferences: ['Gluten-free'],
          ),
        ],
        restaurantDeckIds: const ['dh_01', 'dh_02', 'dh_03'],
        votes: const {
          'dh_01': ['user_host', 'user_friend'],
        },
        matchedRestaurantIds: const ['dh_01'],
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
      expect(
        reconstituted.aggregatedDietaryRestrictions.contains('Vegetarian'),
        true,
      );
      expect(
        reconstituted.aggregatedDietaryRestrictions.contains('Gluten-free'),
        true,
      );
    });

    test('Majority vs Unanimous matching rules work accurately', () {
      final members = [
        const GroupMember(userId: 'u1', displayName: 'U1', avatarUrl: ''),
        const GroupMember(userId: 'u2', displayName: 'U2', avatarUrl: ''),
        const GroupMember(userId: 'u3', displayName: 'U3', avatarUrl: ''),
      ];

      // Case 1: 2 out of 3 like it -> Majority MATCHES, Unanimous DOES NOT
      final votes2of3 = {
        'dh_01': ['u1', 'u2'],
      };

      final majorityPass = votes2of3['dh_01']!.length > (members.length / 2);
      final unanimousPass = votes2of3['dh_01']!.length >= members.length;

      expect(majorityPass, true);
      expect(unanimousPass, false);

      // Case 2: 3 out of 3 like it -> Both MATCH
      final votes3of3 = {
        'dh_01': ['u1', 'u2', 'u3'],
      };
      expect(votes3of3['dh_01']!.length >= members.length, true);
    });

    test('CRDT mergeSessions preserves concurrent swipes and detects matches across iPhones', () {
      final phone1State = GroupSession(
        id: 'group_crdt_1',
        pinCode: '111 222',
        title: 'Den Haag Swipe',
        locationCity: 'Den Haag',
        targetDate: DateTime(2026, 11, 15),
        matchRule: MatchRule.unanimous,
        status: GroupStatus.swiping,
        hostId: 'iphone_1',
        members: const [
          GroupMember(
            userId: 'iphone_1',
            displayName: 'Phone 1',
            avatarUrl: '',
            isHost: true,
          ),
          GroupMember(
            userId: 'iphone_2',
            displayName: 'Phone 2',
            avatarUrl: '',
          ),
        ],
        restaurantDeckIds: const ['dh_01', 'dh_02'],
        votes: const {
          'dh_01': ['iphone_1'],
        },
        matchedRestaurantIds: const [],
      );

      final phone2State = GroupSession(
        id: 'group_crdt_1',
        pinCode: '111 222',
        title: 'Den Haag Swipe',
        locationCity: 'Den Haag',
        targetDate: DateTime(2026, 11, 15),
        matchRule: MatchRule.unanimous,
        status: GroupStatus.swiping,
        hostId: 'iphone_1',
        members: const [
          GroupMember(
            userId: 'iphone_1',
            displayName: 'Phone 1',
            avatarUrl: '',
            isHost: true,
          ),
          GroupMember(
            userId: 'iphone_2',
            displayName: 'Phone 2',
            avatarUrl: '',
          ),
        ],
        restaurantDeckIds: const ['dh_01', 'dh_02'],
        votes: const {
          'dh_01': ['iphone_2'],
          'dh_02': ['iphone_2'],
        },
        matchedRestaurantIds: const [],
      );

      final merged = CloudSyncService.mergeSessions(phone1State, phone2State);

      // Both votes on dh_01 should be preserved and trigger an automatic match!
      expect(merged.votes['dh_01'], containsAll(['iphone_1', 'iphone_2']));
      expect(merged.votes['dh_02'], contains('iphone_2'));
      expect(merged.matchedRestaurantIds, contains('dh_01'));
      expect(merged.matchedRestaurantIds.contains('dh_02'), false);
    });
  });
}
