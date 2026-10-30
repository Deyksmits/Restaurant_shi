import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/restaurant.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/match_dialog.dart';
import '../../widgets/tinder_swipe_deck.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final List<String> _cities = [
    'All Cities',
    'Amsterdam',
    'Rotterdam',
    'Utrecht',
    'Den Haag',
    'Eindhoven',
  ];

  @override
  Widget build(BuildContext context) {
    final restaurants = ref.watch(exploreDeckProvider);
    final selectedCity = ref.watch(selectedCityProvider);
    final db = ref.read(databaseServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 6),
            Text(
              'Explore Hotspots',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Dietary Filters',
            onPressed: () => _showFilterDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // City Selector Horizontal Bar
          SizedBox(
            height: 48,
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
                      city,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

          // Main Swipe Deck
          Expanded(
            child: restaurants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No restaurants found in $selectedCity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try selecting "All Cities" or clearing your dietary filters.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(selectedCityProvider.notifier).state = 'All Cities';
                          },
                          child: const Text('Show All Cities'),
                        ),
                      ],
                    ),
                  )
                : TinderSwipeDeck(
                    key: ValueKey('${selectedCity}_${restaurants.length}'),
                    restaurants: restaurants,
                    onSwipeLeft: (Restaurant r) {
                      db.recordSwipe(restaurantId: r.id, action: 'dislike');
                    },
                    onSwipeRight: (Restaurant r) {
                      db.recordSwipe(restaurantId: r.id, action: 'like');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Saved "${r.name}" to Favourites! ❤️'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    onSwipeUp: (Restaurant r) {
                      db.recordSwipe(restaurantId: r.id, action: 'superlike');
                      MatchDialog.show(
                        context,
                        restaurant: r,
                        onContinue: () {},
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final user = ref.watch(authProvider);
            final currentPrefs = user?.dietaryPreferences ?? [];
            final options = ['Vegetarian', 'Vegan', 'Halal', 'Gluten-free'];

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dietary & Lifestyle Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Restaurants that don\'t match your diet will be excluded from the swipe deck.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((opt) {
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
                          ref.read(authProvider.notifier).updateDietaryPreferences(updated);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: const Text('Apply Filters'),
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
