import 'dart:async';
import 'dart:math';
import '../data/dutch_restaurants_seed.dart';
import '../models/group_session.dart';
import '../models/news_item.dart';
import '../models/restaurant.dart';
import '../models/user_profile.dart';
import 'cloud_sync_service.dart';

class MockDatabaseService {
  static final MockDatabaseService _instance = MockDatabaseService._internal();
  factory MockDatabaseService() => _instance;
  MockDatabaseService._internal() {
    _initData();
  }

  final CloudSyncService _cloudSync = CloudSyncService();
  final List<Restaurant> _restaurants = [];
  final Map<String, GroupSession> _groups = {};
  final List<NewsItem> _newsFeed = [];
  UserProfile? _currentUser;

  /// Unique per-device session suffix so multiple physical iPhones never collide on userId
  late final String _deviceInstanceId;

  // Stream controllers for real-time updates
  final _groupUpdatesController = StreamController<GroupSession>.broadcast();
  final _userUpdatesController = StreamController<UserProfile>.broadcast();

  Stream<GroupSession> watchGroup(String roomId) {
    // Start active real-time cloud synchronization
    _cloudSync.startWatchingGroup(
      roomId,
      onUpdate: (cloudGroup) {
        final existingLocal = _groups[cloudGroup.id];
        final merged = existingLocal != null
            ? CloudSyncService.mergeSessions(existingLocal, cloudGroup)
            : cloudGroup;

        final hadNewLocalMatches =
            merged.matchedRestaurantIds.length >
                cloudGroup.matchedRestaurantIds.length;

        _groups[merged.id] = merged;
        _groups[merged.pinCode] = merged;
        _groupUpdatesController.add(merged);

        // If merging local + remote votes created a new match not yet on cloud, push it back
        if (hadNewLocalMatches) {
          unawaited(_cloudSync.pushGroupToCloud(merged));
        }
      },
    );

    return _groupUpdatesController.stream
        .where((group) => group.id == roomId || group.pinCode == roomId);
  }

  void stopWatchingGroup() {
    _cloudSync.stopWatchingGroup();
  }

  Stream<UserProfile> watchCurrentUser() {
    return _userUpdatesController.stream;
  }

  void _initData() {
    final rng = Random();
    final randNum = 1000 + rng.nextInt(9000);
    _deviceInstanceId = '${DateTime.now().millisecondsSinceEpoch % 100000}_$randNum';

    _restaurants.addAll(kDutchRestaurantsSeed);

    _newsFeed.addAll([
      NewsItem(
        id: 'news_01',
        title: '55+ Den Haag Hotspots Added! 🏖️🏛️',
        subtitle: 'From Scheveningen Strand to Zeeheldenkwartier & Hofkwartier.',
        content:
            'Explore 105 curated restaurants across the Netherlands, including 55 hand-picked gems in The Hague: Encore by Simonis, Café Blossom, Restaurant Zheng, Walter Benedict, and more!',
        imageUrl:
            'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
        publishedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        type: NewsType.appUpdate,
        badgeText: 'Den Haag Edition',
        relatedRestaurantId: 'dh_01',
      ),
      NewsItem(
        id: 'news_02',
        title: 'Live Cloud Group Swiping 🚀',
        subtitle: 'Decide with friends on multiple iPhones Kahoot-style.',
        content:
            'Host a group room, share the 6-digit PIN code, and swipe together in real time via Firebase Cloud Sync. When your group matches, confetti explodes on all screens simultaneously!',
        imageUrl:
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
        publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
        type: NewsType.appUpdate,
        badgeText: 'Live Cloud Sync',
      ),
      NewsItem(
        id: 'news_03',
        title: 'Hotspot Alert: Encore by Simonis 🍣',
        subtitle: 'Asian-fusion & fresh seafood at Scheveningen Haven.',
        content:
            'Enjoy Wagyu Tataki, fresh Yellowfin Tuna, and signature cocktails overlooking the marina in Den Haag.',
        imageUrl:
            'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=800&q=80',
        publishedAt: DateTime.now().subtract(const Duration(hours: 12)),
        type: NewsType.newRestaurant,
        badgeText: 'Den Haag Spotlight',
        relatedRestaurantId: 'dh_01',
      ),
      NewsItem(
        id: 'news_04',
        title: 'Hotspot Alert: Blauw Amsterdam',
        subtitle: 'Famous Indonesian Rijsttafel joins TasteMatch NL.',
        content:
            'Experience 14 vibrant heritage dishes in Oud-Zuid. Special offer: free Spekkoek dessert for groups booking via the app!',
        imageUrl:
            'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=800&q=80',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        type: NewsType.newRestaurant,
        badgeText: 'Trending Hotspot',
        relatedRestaurantId: 'rest_02',
      ),
    ]);

    // Initial default guest user with unique device ID
    _currentUser = UserProfile(
      id: 'usr_guest_$_deviceInstanceId',
      displayName: 'Foodie-$randNum',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
      friendCode: 'FOODIE-$randNum',
      isGuest: true,
      dietaryPreferences: const [],
      favoriteIds: const ['dh_01', 'dh_12'],
      superLikeIds: const ['dh_01'],
      friendIds: const ['usr_sophie', 'usr_daan'],
      incomingFriendRequests: const ['Lars uit Den Haag'],
      swipeHistory: const {},
    );
  }

  // --- Auth methods ---
  UserProfile? get currentUser => _currentUser;

  Future<UserProfile> signInAsGuest({String? nickname}) async {
    final randomCode = 1000 + Random().nextInt(9000);
    final avatars = [
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
      'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=200&q=80',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
    ];
    _currentUser = UserProfile(
      id: 'usr_guest_${DateTime.now().millisecondsSinceEpoch}_$randomCode',
      displayName:
          nickname?.trim().isNotEmpty == true ? nickname!.trim() : 'Foodie-$randomCode',
      avatarUrl: avatars[randomCode % avatars.length],
      friendCode: 'FOODIE-$randomCode',
      isGuest: true,
      favoriteIds: const ['dh_01'],
    );
    _userUpdatesController.add(_currentUser!);
    return _currentUser!;
  }

  Future<UserProfile> signInWithApple() async {
    final randomCode = 1000 + Random().nextInt(9000);
    _currentUser = UserProfile(
      id: 'usr_apple_$_deviceInstanceId',
      displayName: 'Alex de Vries',
      email: 'alex.devries@icloud.com',
      avatarUrl:
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
      friendCode: 'ALEX-$randomCode',
      isGuest: false,
      favoriteIds: const ['dh_01', 'dh_03', 'rest_01'],
    );
    _userUpdatesController.add(_currentUser!);
    return _currentUser!;
  }

  Future<UserProfile> signInWithGoogle() async {
    final randomCode = 1000 + Random().nextInt(9000);
    _currentUser = UserProfile(
      id: 'usr_google_$_deviceInstanceId',
      displayName: 'Emma Jansen',
      email: 'emma.jansen@gmail.com',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
      friendCode: 'EMMA-$randomCode',
      isGuest: false,
      favoriteIds: const ['dh_02', 'rest_02'],
    );
    _userUpdatesController.add(_currentUser!);
    return _currentUser!;
  }

  Future<UserProfile> signInWithPhone(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final randomCode = 1000 + Random().nextInt(9000);
    _currentUser = UserProfile(
      id: 'usr_phone_${cleanPhone}_$_deviceInstanceId',
      displayName: 'Foodie +$cleanPhone',
      phoneNumber: phoneNumber,
      avatarUrl:
          'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=200&q=80',
      friendCode: 'PHONE-$randomCode',
      isGuest: false,
    );
    _userUpdatesController.add(_currentUser!);
    return _currentUser!;
  }

  Future<void> linkGuestAccount({
    required String email,
    required String displayName,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      email: email,
      displayName: displayName,
      isGuest: false,
    );
    _userUpdatesController.add(_currentUser!);
  }

  Future<void> updateDietaryPreferences(List<String> prefs) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(dietaryPreferences: prefs);
    _userUpdatesController.add(_currentUser!);
  }

  // --- Restaurant & Favorites methods ---
  List<Restaurant> get allRestaurants => List.unmodifiable(_restaurants);
  List<NewsItem> get newsFeed => List.unmodifiable(_newsFeed);

  Future<void> toggleFavorite(
    String restaurantId, {
    bool isSuperLike = false,
  }) async {
    if (_currentUser == null) return;
    final currentFavorites = List<String>.from(_currentUser!.favoriteIds);
    final currentSuperLikes = List<String>.from(_currentUser!.superLikeIds);

    if (currentFavorites.contains(restaurantId)) {
      currentFavorites.remove(restaurantId);
      currentSuperLikes.remove(restaurantId);
    } else {
      currentFavorites.add(restaurantId);
      if (isSuperLike) {
        currentSuperLikes.add(restaurantId);
      }
    }

    _currentUser = _currentUser!.copyWith(
      favoriteIds: currentFavorites,
      superLikeIds: currentSuperLikes,
    );
    _userUpdatesController.add(_currentUser!);
  }

  Future<void> recordSwipe({
    required String restaurantId,
    required String action, // "like", "dislike", "superlike"
  }) async {
    if (_currentUser == null) return;
    final history = Map<String, String>.from(_currentUser!.swipeHistory);
    history[restaurantId] = action;

    final currentFavorites = List<String>.from(_currentUser!.favoriteIds);
    final currentSuperLikes = List<String>.from(_currentUser!.superLikeIds);

    if (action == 'like' || action == 'superlike') {
      if (!currentFavorites.contains(restaurantId)) {
        currentFavorites.add(restaurantId);
      }
      if (action == 'superlike' && !currentSuperLikes.contains(restaurantId)) {
        currentSuperLikes.add(restaurantId);
      }
    }

    _currentUser = _currentUser!.copyWith(
      swipeHistory: history,
      favoriteIds: currentFavorites,
      superLikeIds: currentSuperLikes,
    );
    _userUpdatesController.add(_currentUser!);
  }

  Future<void> undoSwipe(String restaurantId) async {
    if (_currentUser == null) return;
    final history = Map<String, String>.from(_currentUser!.swipeHistory);
    history.remove(restaurantId);
    _currentUser = _currentUser!.copyWith(swipeHistory: history);
    _userUpdatesController.add(_currentUser!);
  }

  Future<void> clearSwipeHistory() async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(swipeHistory: const {});
    _userUpdatesController.add(_currentUser!);
  }

  // --- Group Methods ---
  String _generatePinCode() {
    final random = Random();
    final part1 = random.nextInt(900) + 100;
    final part2 = random.nextInt(900) + 100;
    return '$part1 $part2';
  }

  Future<GroupSession> createGroup({
    required String title,
    required String locationCity,
    required DateTime targetDate,
    required MatchRule matchRule,
    String? priceFilter,
    String? categoryFilter,
  }) async {
    final host = _currentUser!;
    final pin = _generatePinCode();
    final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';

    // Filter candidate restaurants for the group deck
    var candidates = _restaurants.where((r) {
      final cityMatch = locationCity.toLowerCase() == 'open' ||
          locationCity.toLowerCase() == 'all cities' ||
          r.city.toLowerCase().contains(locationCity.toLowerCase());
      if (!cityMatch) return false;

      if (priceFilter != null &&
          priceFilter.isNotEmpty &&
          priceFilter != 'All') {
        if (r.priceTier != priceFilter) return false;
      }

      if (categoryFilter != null &&
          categoryFilter.isNotEmpty &&
          categoryFilter != 'All Vibes') {
        final hasCat = r.categories.any(
          (c) => c.toLowerCase().contains(categoryFilter.toLowerCase()),
        );
        if (!hasCat) return false;
      }

      return true;
    }).toList();

    // Sort candidates by rating descending
    candidates.sort((a, b) => b.rating.compareTo(a.rating));

    final deck = candidates.map((r) => r.id).toList();

    // If deck is small (< 5), append top-rated spots from the selected city
    if (deck.length < 5) {
      final cityBackups = _restaurants
          .where(
            (r) =>
                r.city.toLowerCase().contains(locationCity.toLowerCase()) &&
                !deck.contains(r.id),
          )
          .map((r) => r.id);
      deck.addAll(cityBackups);
    }
    if (deck.length < 5) {
      for (final r in _restaurants) {
        if (!deck.contains(r.id)) deck.add(r.id);
      }
    }

    final newGroup = GroupSession(
      id: groupId,
      pinCode: pin,
      title: title.isEmpty ? 'Dinner in $locationCity' : title,
      locationCity: locationCity,
      targetDate: targetDate,
      matchRule: matchRule,
      status: GroupStatus.lobby,
      hostId: host.id,
      members: [
        GroupMember(
          userId: host.id,
          displayName: host.displayName,
          avatarUrl: host.avatarUrl,
          isHost: true,
          isReady: true,
          dietaryPreferences: host.dietaryPreferences,
        ),
      ],
      restaurantDeckIds: deck,
      votes: const {},
      matchedRestaurantIds: const [],
    );

    _groups[groupId] = newGroup;
    _groups[pin] = newGroup;
    _groupUpdatesController.add(newGroup);

    // Push new room to Cloud Database
    unawaited(_cloudSync.pushGroupToCloud(newGroup));

    return newGroup;
  }

  Future<GroupSession?> joinGroupByPin(String pinCode) async {
    final normalized = pinCode.replaceAll(' ', '').trim();
    GroupSession? found;

    // 1. Always try Cloud Database first so we get the freshest lobby state
    found = await _cloudSync.fetchGroupByPin(pinCode);

    // 2. Fallback to local cache if offline
    if (found == null) {
      for (final g in _groups.values) {
        if (g.pinCode.replaceAll(' ', '') == normalized) {
          found = g;
          break;
        }
      }
    }

    if (found == null) return null;
    final user = _currentUser!;

    // Add member if not already in group
    final memberExists = found.members.any((m) => m.userId == user.id);
    if (!memberExists) {
      final updatedMembers = List<GroupMember>.from(found.members)
        ..add(
          GroupMember(
            userId: user.id,
            displayName: user.displayName,
            avatarUrl: user.avatarUrl,
            isHost: false,
            isReady: true,
            dietaryPreferences: user.dietaryPreferences,
          ),
        );

      found = found.copyWith(members: updatedMembers);
    }

    _groups[found.id] = found;
    _groups[found.pinCode] = found;
    _groupUpdatesController.add(found);

    // Publish updated member list to Cloud with CRDT merge
    final synced = await _cloudSync.pushGroupToCloud(found);
    _groups[synced.id] = synced;
    _groups[synced.pinCode] = synced;
    _groupUpdatesController.add(synced);

    return synced;
  }

  Future<void> startGroupSwiping(String groupId) async {
    final group = _groups[groupId];
    if (group == null) return;
    final updated = group.copyWith(status: GroupStatus.swiping);
    _groups[groupId] = updated;
    _groups[updated.pinCode] = updated;
    _groupUpdatesController.add(updated);

    // Sync status change to Cloud
    final synced = await _cloudSync.pushGroupToCloud(updated);
    _groups[synced.id] = synced;
    _groups[synced.pinCode] = synced;
    _groupUpdatesController.add(synced);
  }

  Future<String?> recordGroupSwipe({
    required String groupId,
    required String restaurantId,
    required bool liked,
  }) async {
    final group = _groups[groupId];
    if (group == null || _currentUser == null) return null;

    final previousMatches = Set<String>.from(group.matchedRestaurantIds);
    final userId = _currentUser!.id;
    final updatedVotes = <String, List<String>>{};
    for (final entry in group.votes.entries) {
      updatedVotes[entry.key] = List<String>.from(entry.value);
    }

    if (liked) {
      final currentList = List<String>.from(updatedVotes[restaurantId] ?? []);
      if (!currentList.contains(userId)) {
        currentList.add(userId);
      }
      updatedVotes[restaurantId] = currentList;
    }

    // Check if threshold is met locally for a MATCH
    final voters = updatedVotes[restaurantId] ?? [];
    final totalMembers = max(group.members.length, 1);
    final isLocalMatch = (group.matchRule == MatchRule.unanimous)
        ? voters.length >= totalMembers
        : voters.length > (totalMembers / 2);

    final updatedMatches = List<String>.from(group.matchedRestaurantIds);
    String? newlyMatchedId;

    if (isLocalMatch && !updatedMatches.contains(restaurantId)) {
      updatedMatches.add(restaurantId);
      newlyMatchedId = restaurantId;
    }

    final updated = group.copyWith(
      votes: updatedVotes,
      matchedRestaurantIds: updatedMatches,
    );

    _groups[groupId] = updated;
    _groups[updated.pinCode] = updated;
    _groupUpdatesController.add(updated);

    // Push vote & merge with any concurrent votes in Cloud
    final synced = await _cloudSync.pushGroupToCloud(updated);
    _groups[synced.id] = synced;
    _groups[synced.pinCode] = synced;
    _groupUpdatesController.add(synced);

    if (newlyMatchedId == null &&
        synced.matchedRestaurantIds.contains(restaurantId) &&
        !previousMatches.contains(restaurantId)) {
      newlyMatchedId = restaurantId;
    }

    return newlyMatchedId;
  }

  // --- Interactive Restaurant Owner Portal ---
  Future<void> registerPartnerRestaurant(Restaurant restaurant) async {
    _restaurants.insert(0, restaurant);
    _newsFeed.insert(
      0,
      NewsItem(
        id: 'news_ad_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Partner: ${restaurant.name} 🎉',
        subtitle: restaurant.tagline,
        content:
            'Check out the authentic menu and photo gallery. Now available for group swiping!',
        imageUrl: restaurant.photoUrls.first,
        publishedAt: DateTime.now(),
        type: NewsType.promotion,
        badgeText: 'Sponsored Partner',
        relatedRestaurantId: restaurant.id,
      ),
    );
  }

  // --- Friends system ---
  Future<void> acceptFriendRequest(String request) async {
    if (_currentUser == null) return;
    final reqs = List<String>.from(_currentUser!.incomingFriendRequests)
      ..remove(request);
    final friends = List<String>.from(_currentUser!.friendIds)..add(request);
    _currentUser = _currentUser!.copyWith(
      incomingFriendRequests: reqs,
      friendIds: friends,
    );
    _userUpdatesController.add(_currentUser!);
  }

  Future<void> sendFriendRequest(String friendCode) async {
    if (_currentUser == null) return;
    final friends = List<String>.from(_currentUser!.friendIds)..add(friendCode);
    _currentUser = _currentUser!.copyWith(friendIds: friends);
    _userUpdatesController.add(_currentUser!);
  }
}
