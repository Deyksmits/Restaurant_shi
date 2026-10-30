import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  void _showCreateGroupSheet(BuildContext context) {
    final titleController = TextEditingController(text: 'Borrel & Bites with Friends');
    String selectedCity = 'Amsterdam';
    DateTime selectedDate = DateTime.now();
    MatchRule selectedRule = MatchRule.unanimous;

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
                      'Create Swiping Group',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Get a Kahoot-style PIN code to invite friends and match in real-time.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Session Title',
                        hintText: 'e.g. Friday Drinks, Birthday Dinner',
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
                      items: ['Amsterdam', 'Rotterdam', 'Utrecht', 'Den Haag', 'Eindhoven', 'Open']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedCity = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Matching Rule (Unanimous vs Majority)
                    const Text(
                      'Matching Rule',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Unanimous (100%)'),
                            selected: selectedRule == MatchRule.unanimous,
                            onSelected: (val) {
                              setSheetState(() => selectedRule = MatchRule.unanimous);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Majority (>50%)'),
                            selected: selectedRule == MatchRule.majority,
                            onSelected: (val) {
                              setSheetState(() => selectedRule = MatchRule.majority);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ref.read(activeGroupProvider.notifier).createGroup(
                              title: titleController.text.trim(),
                              locationCity: selectedCity,
                              targetDate: selectedDate,
                              matchRule: selectedRule,
                            );
                      },
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
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

  void _handleJoinWithPin() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    final success = await ref.read(activeGroupProvider.notifier).joinGroup(pin);
    if (!success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room not found. Check the PIN and try again.')),
      );
    } else {
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    final allRestaurants = ref.watch(allRestaurantsProvider);
    final user = ref.watch(authProvider);

    // If already in an active room:
    if (activeGroup != null) {
      if (activeGroup.status == GroupStatus.lobby) {
        return _buildLobbyView(context, activeGroup, user?.id == activeGroup.hostId);
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
                  'Enter the 6-digit room PIN from your friend\'s screen.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
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
                  onPressed: _handleJoinWithPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Enter Lobby 🚀', style: TextStyle(fontSize: 16)),
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
                const Text(
                  'Host a Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Set the city and date, then share your room code via WhatsApp, Instagram or direct link.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
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
            title: 'Create or Join',
            description: 'One person hosts and gets a 6-digit PIN. Friends join on their own phones.',
          ),
          const SizedBox(height: 10),
          _buildInfoStep(
            number: '2',
            title: 'Swipe Together',
            description: 'Everyone sees the same curated deck of restaurants and swipes at the same time.',
          ),
          const SizedBox(height: 10),
          _buildInfoStep(
            number: '3',
            title: 'Instant Matches!',
            description: 'Whenever unanimous or majority consensus is reached, confetti explodes on all screens.',
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
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Live Lobby View ---
  Widget _buildLobbyView(BuildContext context, GroupSession group, bool isHost) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: group.pinCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN copied! Send it to your friends.')),
                    );
                  },
                  icon: const Icon(Icons.copy, color: Colors.white, size: 16),
                  label: const Text('Copy PIN Code', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                  ),
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
                border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.eco_rounded, color: AppColors.accentGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Aggregated Filters: ${group.aggregatedDietaryRestrictions.join(", ")} friendly restaurants prioritized.',
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
              Text(
                'Lobby Friends (${group.members.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  group.matchRule == MatchRule.unanimous ? '100% Unanimous' : 'Majority Rule',
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      backgroundImage: CachedNetworkImageProvider(member.avatarUrl),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      member.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    if (member.isHost) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 16),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 40),

          // Host Start Button
          if (isHost)
            ElevatedButton.icon(
              onPressed: () {
                ref.read(activeGroupProvider.notifier).startSwiping();
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: const Text('Start Group Swiping! 🚀', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            )
          else
            const Center(
              child: Text(
                'Waiting for host to start the swiping session...',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
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
    final deck = allRestaurants
        .where((r) => group.restaurantDeckIds.contains(r.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(group.title),
        actions: [
          // Matches Badge Button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => _showMatchesSummary(context, group, allRestaurants),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.celebration_rounded, color: AppColors.primary, size: 18),
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
        key: ValueKey('group_${group.id}'),
        restaurants: deck,
        onSwipeLeft: (Restaurant r) {
          ref.read(activeGroupProvider.notifier).recordSwipe(
                restaurantId: r.id,
                liked: false,
              );
        },
        onSwipeRight: (Restaurant r) async {
          final matchedId = await ref.read(activeGroupProvider.notifier).recordSwipe(
                restaurantId: r.id,
                liked: true,
              );

          if (matchedId != null && mounted) {
            MatchDialog.show(
              context,
              restaurant: r,
              matchedMemberNames: group.members.map((m) => m.displayName).toList(),
              onContinue: () {},
            );
          }
        },
        onSwipeUp: (Restaurant r) async {
          final matchedId = await ref.read(activeGroupProvider.notifier).recordSwipe(
                restaurantId: r.id,
                liked: true,
              );

          if (matchedId != null && mounted) {
            MatchDialog.show(
              context,
              restaurant: r,
              matchedMemberNames: group.members.map((m) => m.displayName).toList(),
              onContinue: () {},
            );
          }
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, controller) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${matchedRestaurants.length} found',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: matchedRestaurants.isEmpty
                        ? const Center(
                            child: Text(
                              'No matches yet! Keep swiping with your group.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            controller: controller,
                            itemCount: matchedRestaurants.length,
                            itemBuilder: (context, idx) {
                              final r = matchedRestaurants[idx];
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
                                  title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  subtitle: Text('${r.city} • ${r.priceTier} • Rating: ${r.rating} ⭐'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    RestaurantDetailsSheet.show(context, r);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
