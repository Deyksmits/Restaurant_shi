import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/restaurant.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/match_dialog.dart';
import '../../widgets/restaurant_details_sheet.dart';
import '../../widgets/tinder_swipe_deck.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final List<String> _cities = const [
    'All Cities',
    'Den Haag',
    'Rotterdam',
    'Amsterdam',
    'Utrecht',
    'Leiden',
    'Delft',
    'Eindhoven',
  ];

  bool _isBrowseListMode = false;
  bool _showSearchBar = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = ref.watch(exploreDeckProvider);
    final selectedCity = ref.watch(selectedCityProvider);
    final selectedPrice = ref.watch(selectedPriceTierProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final searchQuery = ref.watch(exploreSearchQueryProvider);
    final user = ref.watch(authProvider);
    final db = ref.read(databaseServiceProvider);

    final activeFilterCount = (selectedPrice != 'All' ? 1 : 0) +
        (selectedCategory != 'All Vibes' ? 1 : 0) +
        (user?.dietaryPreferences.length ?? 0);

    final filterSignature =
        '${selectedCity}_${selectedPrice}_${selectedCategory}_${searchQuery}_${user?.dietaryPreferences.join(",")}';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 6),
            const Text(
              'Explore',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${restaurants.length} spots',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Search toggle button
          IconButton(
            icon: Icon(
              _showSearchBar ? Icons.search_off_rounded : Icons.search_rounded,
              color: _showSearchBar ? AppColors.primary : AppColors.textPrimary,
            ),
            tooltip: 'Search by name or neighborhood',
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchController.clear();
                  ref.read(exploreSearchQueryProvider.notifier).state = '';
                }
              });
            },
          ),
          // Toggle between Swipe Deck and Browse List
          IconButton(
            icon: Icon(
              _isBrowseListMode
                  ? Icons.style_rounded
                  : Icons.view_list_rounded,
              color: AppColors.primary,
            ),
            tooltip: _isBrowseListMode ? 'Swipe Mode' : 'Browse List Mode',
            onPressed: () {
              setState(() => _isBrowseListMode = !_isBrowseListMode);
            },
          ),
          // Filter Button with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Filters & Vibe',
                onPressed: () => _showFilterDialog(context),
              ),
              if (activeFilterCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$activeFilterCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search Bar (when active)
          if (_showSearchBar)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) {
                  ref.read(exploreSearchQueryProvider.notifier).state = val;
                },
                decoration: InputDecoration(
                  hintText:
                      'Search name, neighborhood (e.g. Scheveningen, Hofkwartier)...',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(exploreSearchQueryProvider.notifier)
                                .state = '';
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),

          // City Selector Horizontal Bar
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _cities.length,
              itemBuilder: (context, index) {
                final city = _cities[index];
                final isSelected = city == selectedCity;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    selectedColor: AppColors.primary.withOpacity(0.18),
                    checkmarkColor: AppColors.primary,
                    label: Text(
                      city == 'Den Haag' ? '🏖️ Den Haag' : city,
                      style: TextStyle(
                        color:
                            isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    onSelected: (val) {
                      ref.read(selectedCityProvider.notifier).state = city;
                    },
                  ),
                );
              },
            ),
          ),

          // Main Area (Swipe Deck or Browse List)
          Expanded(
            child: restaurants.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No restaurants match your current filters in $selectedCity',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try resetting your filters or restoring previously swiped spots.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  ref.read(selectedCityProvider.notifier).state =
                                      'All Cities';
                                  ref
                                      .read(selectedPriceTierProvider.notifier)
                                      .state = 'All';
                                  ref
                                      .read(
                                        selectedCategoryFilterProvider.notifier,
                                      )
                                      .state = 'All Vibes';
                                  ref
                                      .read(exploreSearchQueryProvider.notifier)
                                      .state = '';
                                  ref
                                      .read(authProvider.notifier)
                                      .updateDietaryPreferences([]);
                                },
                                icon: const Icon(Icons.filter_alt_off_rounded),
                                label: const Text('Clear Filters'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  ref
                                      .read(authProvider.notifier)
                                      .resetSwipes();
                                },
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Reset Swiped History'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : _isBrowseListMode
                    ? _buildBrowseListView(context, restaurants)
                    : TinderSwipeDeck(
                        key: ValueKey(filterSignature),
                        restaurants: restaurants,
                        onSwipeLeft: (Restaurant r) {
                          db.recordSwipe(restaurantId: r.id, action: 'dislike');
                        },
                        onSwipeRight: (Restaurant r) {
                          db.recordSwipe(restaurantId: r.id, action: 'like');
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Saved "${r.name}" to Favourites! ❤️'),
                              duration: const Duration(milliseconds: 1100),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        onSwipeUp: (Restaurant r) {
                          db.recordSwipe(
                            restaurantId: r.id,
                            action: 'superlike',
                          );
                          MatchDialog.show(
                            context,
                            restaurant: r,
                            onContinue: () {},
                          );
                        },
                        onUndo: (Restaurant r) {
                          ref.read(authProvider.notifier).undoSwipe(r.id);
                        },
                        onResetRequested: () {
                          ref.read(authProvider.notifier).resetSwipes();
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseListView(
    BuildContext context,
    List<Restaurant> restaurants,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final r = restaurants[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: r.photoUrls.first,
                width: 68,
                height: 68,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              r.name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  '${r.neighborhood}, ${r.city} • ${r.priceTier}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  r.categories.join(' • '),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.accentGold,
                      size: 16,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      r.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
            onTap: () => RestaurantDetailsSheet.show(context, r),
          ),
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    final priceOptions = ['All', '€', '€€', '€€€', '€€€€'];
    final categoryOptions = [
      'All Vibes',
      'Seafood',
      'Borrel',
      'Asian',
      'Italian',
      'Indonesian',
      'French',
      'Beachclub',
      'Cocktails',
      'Fine Dining',
    ];
    final dietaryOptions = ['Vegetarian', 'Vegan', 'Halal', 'Gluten-free'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final user = ref.watch(authProvider);
            final currentPrefs = user?.dietaryPreferences ?? [];
            final selectedPrice = ref.watch(selectedPriceTierProvider);
            final selectedCat = ref.watch(selectedCategoryFilterProvider);

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filters & Vibe 🎯',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref
                                .read(selectedPriceTierProvider.notifier)
                                .state = 'All';
                            ref
                                .read(selectedCategoryFilterProvider.notifier)
                                .state = 'All Vibes';
                            ref
                                .read(authProvider.notifier)
                                .updateDietaryPreferences([]);
                          },
                          child: const Text('Reset All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Price Filter
                    const Text(
                      'Budget / Price Tier',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
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
                            ref
                                .read(selectedPriceTierProvider.notifier)
                                .state = p;
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Category / Vibe Filter
                    const Text(
                      'Cuisine & Vibe',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: categoryOptions.map((cat) {
                        final isSelected = selectedCat == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) {
                            ref
                                .read(selectedCategoryFilterProvider.notifier)
                                .state = cat;
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Dietary Filter
                    const Text(
                      'Dietary & Lifestyle',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dietaryOptions.map((opt) {
                        final isSelected = currentPrefs.contains(opt);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(opt),
                          selectedColor: AppColors.accentGreen.withOpacity(0.2),
                          checkmarkColor: AppColors.accentGreen,
                          onSelected: (val) {
                            final updated = List<String>.from(currentPrefs);
                            if (val) {
                              updated.add(opt);
                            } else {
                              updated.remove(opt);
                            }
                            ref
                                .read(authProvider.notifier)
                                .updateDietaryPreferences(updated);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Apply Filters'),
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
}
