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

  // Stream controllers for real-time updates
  final _groupUpdatesController = StreamController<GroupSession>.broadcast();
  final _userUpdatesController = StreamController<UserProfile>.broadcast();

  Stream<GroupSession> watchGroup(String roomId) {
    // Start active real-time cloud synchronization
    _cloudSync.startWatchingGroup(
      roomId,
      onUpdate: (cloudGroup) {
        _groups[cloudGroup.id] = cloudGroup;
        _groups[cloudGroup.pinCode] = cloudGroup;
        _groupUpdatesController.add(cloudGroup);
      },
    );

    return _groupUpdatesController.stream.where((group) => group.id == roomId || group.pinCode == roomId);
  }

  void stopWatchingGroup() {
    _cloudSync.stopWatchingGroup();
  }

  Stream<UserProfile> watchCurrentUser() {
    return _userUpdatesController.stream;
  }

  void _initData() {
    _restaurants.addAll(kDutchRestaurantsSeed);

    _newsFeed.addAll([
      NewsItem(
        id: 'news_01',
        title: 'New: Real-time Group Swiping! 🚀',
        subtitle: 'Decide with friends in seconds Kahoot-style.',
        content: 'Create a room, share the 6-digit PIN code or invite link, and swipe through Dutch hotspots together. When everyone likes the same spot, you get an instant match!',
        imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
        publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
        type: NewsType.appUpdate,
        badgeText: 'Update v1.0',
      ),
      NewsItem(
        id: 'news_02',
        title: 'Hotspot Alert: Blauw Amsterdam',
        subtitle: 'Famous Indonesian Rijsttafel joins TasteMatch NL.',
        content: 'Experience 14 vibrant heritage dishes in Oud-Zuid. Special offer: free Spekkoek dessert for groups booking via the app!',
        imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=800&q=80',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        type: NewsType.newRestaurant,
        badgeText: 'Trending Hotspot',
        relatedRestaurantId: 'rest_02',
      ),
      NewsItem(
        id: 'news_03',
        title: 'Friend Activity',
        subtitle: 'Sophie and Daan matched on Café de Klos!',
        content: 'Your friends just matched for dinner tonight in Amsterdam. Send them a message or plan your own evening.',
        imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
        type: NewsType.friendActivity,
        badgeText: 'Social',
        relatedRestaurantId: 'rest_01',
      ),
    ]);

    // Initial default guest user
    _currentUser = const UserProfile(
      id: 'usr_guest_demo',
      displayName: 'Guest Foodie',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
      friendCode: 'FOODIE-4821',
      isGuest: true,
      dietaryPreferences: [],
      favoriteIds: ['rest_01'],
      superLikeIds: [],
      friendIds: ['usr_sophie', 'usr_daan'],
      incomingFriendRequests: ['Lars from Amsterdam'],
      swipeHistory: {},
    );
  }

  // --- Auth methods ---
  UserProfile? get currentUser => _currentUser;

  Future<UserProfile> signInAsGuest({String? nickname}) async {
    final randomCode = 1000 + Random().nextInt(9000);
    _currentUser = UserProfile(
      id: 'usr_guest_${DateTime.now().millisecondsSinceEpoch}',
      displayName: nickname?.isNotEmpty == true ? nickname! : 'Foodie-$randomCode',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
      friendCode: 'FOODIE-$randomCode',
      isGuest: true,
    );
    _userUpdatesController.add(_currentUser!);
    return _currentUser!;
  }

  Future<UserProfile> signInWithApple() async {
    _currentUser = const UserProfile(
      id: 'usr_apple_102',
      displayName: 'Alex de Vries',
      email: 'alex.devries@icloud.com',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
      friendCode: 'ALEX-7791',
      isGuest: false,
      favoriteIds: ['rest_01', 'rest_03'],
    );
    _userUpdatesController.add(_currentUser!);
    return _currentUser!;
  }

  Future<UserProfile> signInWithGoogle() async {
    _currentUser = const UserProfile(
      id: 'usr_google_304',
      displayName: 'Emma Jansen',
      email: 'emma.jansen@gmail.com',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
      friendCode: 'EMMA-2390',
      isGuest: false,
      favoriteIds: ['rest_02', 'rest_04'],
    );
    _userUpdatesController.add(_currentUser!);
    return _currentUser!;
  }

  Future<UserProfile> signInWithPhone(String phoneNumber) async {
    _currentUser = UserProfile(
      id: 'usr_phone_${phoneNumber.replaceAll(RegExp(r'\D'), '')}',
      displayName: 'Mobile Foodie',
      phoneNumber: phoneNumber,
      avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=200&q=80',
      friendCode: 'PHONE-${Random().nextInt(8999) + 1000}',
      isGuest: false,
    );
    _userUpdatesController.add(_currentUser!);
    return _currentUser!;
  }

  Future<void> linkGuestAccount({required String email, required String displayName}) async {
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

  Future<void> toggleFavorite(String restaurantId, {bool isSuperLike = false}) async {
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
  }) async {
    final host = _currentUser!;
    final pin = _generatePinCode();
    final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';

    // Build initial restaurant deck for the selected city
    final deck = _restaurants
        .where((r) =>
            locationCity.toLowerCase() == 'open' ||
            locationCity.toLowerCase() == 'all cities' ||
            r.city.toLowerCase().contains(locationCity.toLowerCase()))
        .map((r) => r.id)
        .toList();

    // If deck is small, add other popular NL restaurants
    if (deck.length < 5) {
      for (final r in _restaurants) {
        if (!deck.contains(r.id)) deck.add(r.id);
      }
    }

    final newGroup = GroupSession(
      id: groupId,
      pinCode: pin,
      title: title,
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
      votes: {},
      matchedRestaurantIds: [],
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

    // 1. Check local cache
    for (final g in _groups.values) {
      if (g.pinCode.replaceAll(' ', '') == normalized) {
        found = g;
        break;
      }
    }

    // 2. Query Cloud Database if not found in local memory (e.g. created on another iPhone)
    found ??= await _cloudSync.fetchGroupByPin(pinCode);

    if (found == null) return null;
    final user = _currentUser!;

    // Check if already in group
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
      _groups[found.id] = found;
      _groups[found.pinCode] = found;
      _groupUpdatesController.add(found);

      // Publish updated member list to Cloud
      unawaited(_cloudSync.pushGroupToCloud(found));
    }

    return found;
  }

  Future<void> startGroupSwiping(String groupId) async {
    final group = _groups[groupId];
    if (group == null) return;
    final updated = group.copyWith(status: GroupStatus.swiping);
    _groups[groupId] = updated;
    _groups[updated.pinCode] = updated;
    _groupUpdatesController.add(updated);

    // Sync status change to Cloud
    unawaited(_cloudSync.pushGroupToCloud(updated));
  }

  Future<String?> recordGroupSwipe({
    required String groupId,
    required String restaurantId,
    required bool liked,
  }) async {
    final group = _groups[groupId];
    if (group == null || _currentUser == null) return null;

    final userId = _currentUser!.id;
    final updatedVotes = Map<String, List<String>>.from(group.votes);

    if (liked) {
      final currentList = List<String>.from(updatedVotes[restaurantId] ?? []);
      if (!currentList.contains(userId)) {
        currentList.add(userId);
      }
      updatedVotes[restaurantId] = currentList;
    }

    // Check if threshold is met for a MATCH
    final voters = updatedVotes[restaurantId] ?? [];
    final totalMembers = max(group.members.length, 1);
    bool isMatch = false;

    if (group.matchRule == MatchRule.unanimous) {
      isMatch = voters.length >= totalMembers;
    } else {
      // Majority: > 50%
      isMatch = voters.length > (totalMembers / 2);
    }

    final updatedMatches = List<String>.from(group.matchedRestaurantIds);
    String? newlyMatchedId;

    if (isMatch && !updatedMatches.contains(restaurantId)) {
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

    // Push vote and match status to Cloud
    unawaited(_cloudSync.pushGroupToCloud(updated));

    return newlyMatchedId;
  }

  // --- Interactive Restaurant Owner Portal ---
  Future<void> registerPartnerRestaurant(Restaurant restaurant) async {
    _restaurants.insert(0, restaurant);
    // Add to news feed as newly opened sponsored partner
    _newsFeed.insert(
      0,
      NewsItem(
        id: 'news_ad_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Partner: ${restaurant.name} 🎉',
        subtitle: restaurant.tagline,
        content: 'Check out the authentic menu and photo gallery. Now available for group swiping!',
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
    final reqs = List<String>.from(_currentUser!.incomingFriendRequests)..remove(request);
    final friends = List<String>.from(_currentUser!.friendIds)..add(request);
    _currentUser = _currentUser!.copyWith(
      incomingFriendRequests: reqs,
      friendIds: friends,
    );
    _userUpdatesController.add(_currentUser!);
  }

  Future<void> sendFriendRequest(String friendCode) async {
    // Simulated instant connection for prototype testing
    if (_currentUser == null) return;
    final friends = List<String>.from(_currentUser!.friendIds)..add(friendCode);
    _currentUser = _currentUser!.copyWith(friendIds: friends);
    _userUpdatesController.add(_currentUser!);
  }
}
