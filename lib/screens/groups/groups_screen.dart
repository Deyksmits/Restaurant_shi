import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/group_session.dart';
import '../../models/restaurant.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/match_dialog.dart';
import '../../widgets/restaurant_details_sheet.dart';
import '../../widgets/tinder_swipe_deck.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  final _pinController = TextEditingController();
  final Set<String> _celebratedMatchIds = {};
  bool _isJoining = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _showCreateGroupSheet(BuildContext context) {
    final titleController =
        TextEditingController(text: 'Den Haag Dinner & Borrel');
    String selectedCity = 'Den Haag';
    String selectedPrice = 'All';
    String selectedCategory = 'All Vibes';
    DateTime selectedDate = DateTime.now();
    MatchRule selectedRule = MatchRule.unanimous;

    final cities = [
      'Den Haag',
      'Rotterdam',
      'Amsterdam',
      'Utrecht',
      'Leiden',
      'Delft',
      'Eindhoven',
      'All Cities',
    ];
    final priceOptions = ['All', '€', '€€', '€€€', '€€€€'];
    final categoryOptions = [
      'All Vibes',
      'Seafood',
      'Borrel',
      'Asian',
      'Italian',
      'Beachclub',
      'Fine Dining',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Swiping Group 🎯',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Generate a 6-digit Kahoot-style PIN code to swipe live with friends on multiple iPhones.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Session Title',
                        hintText: 'e.g. Friday Drinks, Scheveningen Dinner',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // City
                    DropdownButtonFormField<String>(
                      value: selectedCity,
                      decoration: const InputDecoration(
                        labelText: 'Location / City',
                        border: OutlineInputBorder(),
                      ),
                      items: cities
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedCity = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Vibe / Category Filter
                    const Text(
                      'Vibe / Cuisine Filter',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: categoryOptions.map((cat) {
                        final isSelected = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) {
                            setSheetState(() => selectedCategory = cat);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Price Filter
                    const Text(
                      'Budget / Price Tier',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: priceOptions.map((p) {
                        final isSelected = selectedPrice == p;
                        return ChoiceChip(
                          label: Text(p),
                          selected: isSelected,
                          onSelected: (_) {
                            setSheetState(() => selectedPrice = p);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Matching Rule (Unanimous vs Majority)
                    const Text(
                      'Matching Rule',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Unanimous (100%)'),
                            selected: selectedRule == MatchRule.unanimous,
                            onSelected: (val) {
                              setSheetState(
                                () => selectedRule = MatchRule.unanimous,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Majority (>50%)'),
                            selected: selectedRule == MatchRule.majority,
                            onSelected: (val) {
                              setSheetState(
                                () => selectedRule = MatchRule.majority,
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        _celebratedMatchIds.clear();
                        await ref
                            .read(activeGroupProvider.notifier)
                            .createGroup(
                              title: titleController.text.trim(),
                              locationCity: selectedCity,
                              targetDate: selectedDate,
                              matchRule: selectedRule,
                              priceFilter: selectedPrice,
                              categoryFilter: selectedCategory,
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Create Room & Generate PIN 🎯'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleJoinWithPin() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty || _isJoining) return;

    setState(() => _isJoining = true);
    _celebratedMatchIds.clear();
    final success = await ref.read(activeGroupProvider.notifier).joinGroup(pin);
    if (!mounted) return;
    setState(() => _isJoining = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room not found. Check the 6-digit PIN and try again.'),
        ),
      );
    } else {
      HapticFeedback.mediumImpact();
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    final allRestaurants = ref.watch(allRestaurantsProvider);
    final user = ref.watch(authProvider);

    // Listen for real-time matches across all connected iPhones!
    ref.listen<GroupSession?>(activeGroupProvider, (previous, next) {
      if (next == null) {
        _celebratedMatchIds.clear();
        return;
      }

      for (final matchedId in next.matchedRestaurantIds) {
        if (!_celebratedMatchIds.contains(matchedId)) {
          _celebratedMatchIds.add(matchedId);
          final matchedRest = allRestaurants.where((r) => r.id == matchedId);
          if (matchedRest.isNotEmpty && mounted) {
            HapticFeedback.heavyImpact();
            MatchDialog.show(
              context,
              restaurant: matchedRest.first,
              matchedMemberNames:
                  next.members.map((m) => m.displayName).toList(),
              onContinue: () {},
            );
          }
          break;
        }
      }
    });

    // If already in an active room:
    if (activeGroup != null) {
      if (activeGroup.status == GroupStatus.lobby) {
        return _buildLobbyView(
          context,
          activeGroup,
          user?.id == activeGroup.hostId,
        );
      } else {
        return _buildGroupSwipingView(context, activeGroup, allRestaurants);
      }
    }

    // Default view: Join or Create Group Hub
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Swiping Hub 🎯'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. Join with PIN Card (Kahoot-style)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pin_rounded, color: AppColors.primary, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Join with Game PIN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the 6-digit room PIN from your friend\'s iPhone screen.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onSubmitted: (_) => _handleJoinWithPin(),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: AppColors.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. 482 910',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 20,
                      letterSpacing: 2,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isJoining ? null : _handleJoinWithPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isJoining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Enter Lobby 🚀',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Create Group Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_done_rounded,
                            color: AppColors.accentGreen,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'FIREBASE LIVE SYNC',
                            style: TextStyle(
                              color: AppColors.accentGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Host a Group Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pick Den Haag or any Dutch city, choose your vibe, and share your 6-digit PIN via WhatsApp.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _showCreateGroupSheet(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create New Room'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Quick Explanation Cards
          const Text(
            'How Group Swiping Works',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _buildInfoStep(
            number: '1',
            title: 'Create or Join via 6-Digit PIN',
            description:
                'One person hosts a room (e.g. Den Haag). Friends join on their own iPhones using the PIN.',
          ),
          const SizedBox(height: 10),
          _buildInfoStep(
            number: '2',
            title: 'Real-Time Cloud Swiping',
            description:
                'Everyone swipes through the same curated restaurant deck synced live via Firebase.',
          ),
          const SizedBox(height: 10),
          _buildInfoStep(
            number: '3',
            title: 'Simultaneous Confetti Matches!',
            description:
                'The moment unanimous or majority consensus is reached, confetti explodes on every phone!',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Live Lobby View ---
  Widget _buildLobbyView(
    BuildContext context,
    GroupSession group,
    bool isHost,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ref.read(activeGroupProvider.notifier).leaveGroup();
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Kahoot Big PIN Code Box
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFFFF7E5F)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '📍 ${group.locationCity.toUpperCase()} • ${group.restaurantDeckIds.length} SPOTS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'GAME PIN',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  group.pinCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: group.pinCode));
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PIN copied to clipboard! 📋'),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.copy_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: const Text(
                        'Copy PIN',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Share.share(
                          '🍽️ Join our TasteMatch restaurant swipe room for ${group.locationCity}!\n\n🔑 Game PIN: ${group.pinCode}\n\nOpen TasteMatch -> Groups -> Enter PIN!',
                        );
                      },
                      icon: const Icon(
                        Icons.ios_share_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      label: const Text(
                        'Share Invite',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Aggregated Dietary Restrictions Warning / Info
          if (group.aggregatedDietaryRestrictions.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accentGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.eco_rounded, color: AppColors.accentGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Group Dietary Filters: ${group.aggregatedDietaryRestrictions.join(", ")} friendly spots prioritized.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Participants Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Connected Friends (${group.members.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  group.matchRule == MatchRule.unanimous
                      ? '100% Unanimous'
                      : 'Majority (>50%)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Members Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: group.members.map((member) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage:
                          CachedNetworkImageProvider(member.avatarUrl),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      member.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if (member.isHost) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.accentGold,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 36),

          // Host Start Button
          if (isHost)
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(activeGroupProvider.notifier).startSwiping();
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: const Text(
                'Start Group Swiping! 🚀',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Waiting for host to start the session...',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- Synchronized Swiping View ---
  Widget _buildGroupSwipingView(
    BuildContext context,
    GroupSession group,
    List<Restaurant> allRestaurants,
  ) {
    final restaurantMap = {for (final r in allRestaurants) r.id: r};
    final deck = group.restaurantDeckIds
        .map((id) => restaurantMap[id])
        .whereType<Restaurant>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app_rounded),
          tooltip: 'Leave Group',
          onPressed: () {
            ref.read(activeGroupProvider.notifier).leaveGroup();
          },
        ),
        title: Column(
          children: [
            Text(
              group.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              'PIN: ${group.pinCode} • ${group.members.length} online',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.accentGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          // Matches & Leaderboard Badge Button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => _showMatchesSummary(context, group, allRestaurants),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.celebration_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${group.matchedRestaurantIds.length} Matches',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: TinderSwipeDeck(
        key: ValueKey('group_deck_${group.id}'),
        restaurants: deck,
        onSwipeLeft: (Restaurant r) {
          ref.read(activeGroupProvider.notifier).recordSwipe(
                restaurantId: r.id,
                liked: false,
              );
        },
        onSwipeRight: (Restaurant r) {
          ref.read(activeGroupProvider.notifier).recordSwipe(
                restaurantId: r.id,
                liked: true,
              );
        },
        onSwipeUp: (Restaurant r) {
          ref.read(activeGroupProvider.notifier).recordSwipe(
                restaurantId: r.id,
                liked: true,
              );
        },
        onDeckEmpty: () {
          _showMatchesSummary(context, group, allRestaurants);
        },
      ),
    );
  }

  void _showMatchesSummary(
    BuildContext context,
    GroupSession group,
    List<Restaurant> allRestaurants,
  ) {
    final matchedRestaurants = allRestaurants
        .where((r) => group.matchedRestaurantIds.contains(r.id))
        .toList();

    // Also compute leading contenders (restaurants with >= 1 vote not yet matched)
    final contenders = allRestaurants
        .where(
          (r) =>
              !group.matchedRestaurantIds.contains(r.id) &&
              (group.votes[r.id]?.isNotEmpty ?? false),
        )
        .toList()
      ..sort(
        (a, b) => (group.votes[b.id]?.length ?? 0)
            .compareTo(group.votes[a.id]?.length ?? 0),
      );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, controller) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Group Matches 🎉',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${matchedRestaurants.length} matched',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (matchedRestaurants.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.swipe_rounded,
                            size: 36,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No full matches yet! Keep swiping with your group.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    ...matchedRestaurants.map((r) {
                      final voteCount =
                          group.votes[r.id]?.length ?? group.members.length;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: r.photoUrls.first,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            r.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${r.neighborhood}, ${r.city} • ${r.priceTier} • $voteCount/${group.members.length} votes ⭐',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.ios_share_rounded,
                              color: AppColors.primary,
                            ),
                            onPressed: () {
                              Share.share(
                                '🎉 It\'s a Match on TasteMatch! We\'re going to ${r.name} in ${r.neighborhood}, ${r.city} (${r.rating}⭐)!',
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            RestaurantDetailsSheet.show(context, r);
                          },
                        ),
                      );
                    }),

                  if (contenders.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Leading Contenders (Votes So Far) 📊',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...contenders.take(10).map((r) {
                      final voteCount = group.votes[r.id]?.length ?? 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: r.photoUrls.first,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            r.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text('${r.neighborhood}, ${r.city}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$voteCount / ${group.members.length} ❤️',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            RestaurantDetailsSheet.show(context, r);
                          },
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
