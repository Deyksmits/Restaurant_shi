import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_session.dart';
import '../models/news_item.dart';
import '../models/restaurant.dart';
import '../models/user_profile.dart';
import '../services/mock_database_service.dart';
import '../services/taste_algorithm_service.dart';

// 1. Database Service Singleton Provider
final databaseServiceProvider = Provider<MockDatabaseService>((ref) {
  return MockDatabaseService();
});

// 2. Auth & Current User Provider
class AuthNotifier extends StateNotifier<UserProfile?> {
  final MockDatabaseService _db;

  AuthNotifier(this._db) : super(_db.currentUser) {
    _db.watchCurrentUser().listen((user) {
      state = user;
    });
  }

  Future<void> signInAsGuest({String? nickname}) async {
    state = await _db.signInAsGuest(nickname: nickname);
  }

  Future<void> signInWithApple() async {
    state = await _db.signInWithApple();
  }

  Future<void> signInWithGoogle() async {
    state = await _db.signInWithGoogle();
  }

  Future<void> signInWithPhone(String phoneNumber) async {
    state = await _db.signInWithPhone(phoneNumber);
  }

  Future<void> linkAccount({required String email, required String displayName}) async {
    await _db.linkGuestAccount(email: email, displayName: displayName);
    state = _db.currentUser;
  }

  Future<void> updateDietaryPreferences(List<String> prefs) async {
    await _db.updateDietaryPreferences(prefs);
    state = _db.currentUser;
  }

  Future<void> acceptFriendRequest(String request) async {
    await _db.acceptFriendRequest(request);
    state = _db.currentUser;
  }

  Future<void> sendFriendRequest(String code) async {
    await _db.sendFriendRequest(code);
    state = _db.currentUser;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserProfile?>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return AuthNotifier(db);
});

// 3. Restaurants Provider
final allRestaurantsProvider = Provider<List<Restaurant>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.allRestaurants;
});

// 4. News Feed Provider
final newsFeedProvider = Provider<List<NewsItem>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.newsFeed;
});

// 5. City Filter Provider
final selectedCityProvider = StateProvider<String>((ref) => 'All Cities');

// 6. Solo Explore Adaptive Deck Provider
final exploreDeckProvider = Provider<List<Restaurant>>((ref) {
  final all = ref.watch(allRestaurantsProvider);
  final user = ref.watch(authProvider);
  final city = ref.watch(selectedCityProvider);

  if (user == null) return all;

  return TasteAlgorithmService.rankDeck(
    allRestaurants: all,
    user: user,
    preferredCity: city,
  );
});

// 7. Favorites & Superlikes
final favoriteRestaurantsProvider = Provider<List<Restaurant>>((ref) {
  final all = ref.watch(allRestaurantsProvider);
  final user = ref.watch(authProvider);
  if (user == null) return [];

  return all.where((r) => user.favoriteIds.contains(r.id)).toList();
});

// 8. Active Group Session Provider
class ActiveGroupNotifier extends StateNotifier<GroupSession?> {
  final MockDatabaseService _db;

  ActiveGroupNotifier(this._db) : super(null);

  Future<GroupSession> createGroup({
    required String title,
    required String locationCity,
    required DateTime targetDate,
    required MatchRule matchRule,
  }) async {
    final group = await _db.createGroup(
      title: title,
      locationCity: locationCity,
      targetDate: targetDate,
      matchRule: matchRule,
    );
    state = group;

    _db.watchGroup(group.id).listen((updated) {
      state = updated;
    });

    return group;
  }

  Future<bool> joinGroup(String pinCode) async {
    final group = await _db.joinGroupByPin(pinCode);
    if (group != null) {
      state = group;
      _db.watchGroup(group.id).listen((updated) {
        state = updated;
      });
      return true;
    }
    return false;
  }

  Future<void> startSwiping() async {
    if (state == null) return;
    await _db.startGroupSwiping(state!.id);
  }

  Future<String?> recordSwipe({
    required String restaurantId,
    required bool liked,
  }) async {
    if (state == null) return null;
    return await _db.recordGroupSwipe(
      groupId: state!.id,
      restaurantId: restaurantId,
      liked: liked,
    );
  }

  void leaveGroup() {
    _db.stopWatchingGroup();
    state = null;
  }
}

final activeGroupProvider = StateNotifierProvider<ActiveGroupNotifier, GroupSession?>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return ActiveGroupNotifier(db);
});

// 9. Restaurant Owner Portal State (Mocked Analytics & Venue Registration)
class AdvertiserVenueState {
  final List<Restaurant> registeredVenues;
  final int totalImpressions;
  final int totalRightSwipes;
  final int totalGroupMatches;

  const AdvertiserVenueState({
    required this.registeredVenues,
    required this.totalImpressions,
    required this.totalRightSwipes,
    required this.totalGroupMatches,
  });

  AdvertiserVenueState copyWith({
    List<Restaurant>? registeredVenues,
    int? totalImpressions,
    int? totalRightSwipes,
    int? totalGroupMatches,
  }) {
    return AdvertiserVenueState(
      registeredVenues: registeredVenues ?? this.registeredVenues,
      totalImpressions: totalImpressions ?? this.totalImpressions,
      totalRightSwipes: totalRightSwipes ?? this.totalRightSwipes,
      totalGroupMatches: totalGroupMatches ?? this.totalGroupMatches,
    );
  }
}

class AdvertiserNotifier extends StateNotifier<AdvertiserVenueState> {
  final MockDatabaseService _db;

  AdvertiserNotifier(this._db)
      : super(
          const AdvertiserVenueState(
            registeredVenues: [],
            totalImpressions: 14820,
            totalRightSwipes: 4310,
            totalGroupMatches: 924,
          ),
        );

  Future<void> registerNewVenue(Restaurant restaurant) async {
    await _db.registerPartnerRestaurant(restaurant);
    state = state.copyWith(
      registeredVenues: [restaurant, ...state.registeredVenues],
      totalImpressions: state.totalImpressions + 50,
    );
  }
}

final advertiserProvider = StateNotifierProvider<AdvertiserNotifier, AdvertiserVenueState>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return AdvertiserNotifier(db);
});
