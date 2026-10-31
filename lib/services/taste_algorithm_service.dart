import '../models/restaurant.dart';
import '../models/user_profile.dart';

class TasteAlgorithmService {
  /// Ranks restaurants adaptively based on the user's historical swipe tastes,
  /// dietary restrictions, city preference, price filter, category filter, and search query.
  static List<Restaurant> rankDeck({
    required List<Restaurant> allRestaurants,
    required UserProfile user,
    String? preferredCity,
    Set<String>? requiredDietaryTags,
    String? priceFilter,
    String? categoryFilter,
    String? searchQuery,
  }) {
    // 1. Build category affinity score from past swipe history
    final categoryAffinities = <String, double>{};

    for (final entry in user.swipeHistory.entries) {
      final restaurantId = entry.key;
      final action = entry.value;

      final matched = allRestaurants.where((r) => r.id == restaurantId);
      if (matched.isEmpty) continue;
      final rest = matched.first;

      final weight = (action == 'superlike')
          ? 3.0
          : (action == 'like')
              ? 1.5
              : -2.0;

      for (final cat in rest.categories) {
        categoryAffinities[cat] = (categoryAffinities[cat] ?? 0.0) + weight;
      }
    }

    // 2. Filter & score candidate restaurants
    final scoredRestaurants = <MapEntry<Restaurant, double>>[];
    final cleanQuery = searchQuery?.trim().toLowerCase() ?? '';

    for (final restaurant in allRestaurants) {
      // Exclude if already swiped by solo user (unless searching specifically)
      if (cleanQuery.isEmpty && user.swipeHistory.containsKey(restaurant.id)) {
        continue;
      }

      // Filter by city if specified
      if (preferredCity != null &&
          preferredCity.isNotEmpty &&
          preferredCity.toLowerCase() != 'all cities' &&
          preferredCity.toLowerCase() != 'open') {
        if (!restaurant.city.toLowerCase().contains(preferredCity.toLowerCase())) {
          continue;
        }
      }

      // Filter by price tier if specified
      if (priceFilter != null &&
          priceFilter.isNotEmpty &&
          priceFilter != 'All') {
        if (restaurant.priceTier != priceFilter) {
          continue;
        }
      }

      // Filter by category/vibe if specified
      if (categoryFilter != null &&
          categoryFilter.isNotEmpty &&
          categoryFilter != 'All Vibes') {
        final hasCat = restaurant.categories.any(
          (c) => c.toLowerCase().contains(categoryFilter.toLowerCase()),
        );
        if (!hasCat) {
          continue;
        }
      }

      // Filter by search query (name, neighborhood, tagline, categories)
      if (cleanQuery.isNotEmpty) {
        final matchesName = restaurant.name.toLowerCase().contains(cleanQuery);
        final matchesNeighborhood =
            restaurant.neighborhood.toLowerCase().contains(cleanQuery);
        final matchesCity = restaurant.city.toLowerCase().contains(cleanQuery);
        final matchesTagline =
            restaurant.tagline.toLowerCase().contains(cleanQuery);
        final matchesCategory = restaurant.categories.any(
          (c) => c.toLowerCase().contains(cleanQuery),
        );
        if (!matchesName &&
            !matchesNeighborhood &&
            !matchesCity &&
            !matchesTagline &&
            !matchesCategory) {
          continue;
        }
      }

      // Check aggregated dietary restrictions
      final dietaryNeeds = requiredDietaryTags ?? user.dietaryPreferences.toSet();
      bool isDietaryCompatible = true;
      for (final diet in dietaryNeeds) {
        final matches = restaurant.dietaryTags.any(
          (tag) => tag.toLowerCase().contains(diet.toLowerCase()),
        );
        if (!matches) {
          isDietaryCompatible = false;
          break;
        }
      }

      if (!isDietaryCompatible) {
        continue;
      }

      // Calculate score
      double score = 10.0; // Base score

      // Category taste bonus
      for (final cat in restaurant.categories) {
        score += (categoryAffinities[cat] ?? 0.0);
      }

      // Rating boost (4.5 rating -> +4.5)
      score += restaurant.rating;

      // Sponsored restaurant mild boost for visibility
      if (restaurant.isSponsored) {
        score += 2.0;
      }

      scoredRestaurants.add(MapEntry(restaurant, score));
    }

    // Sort descending by score
    scoredRestaurants.sort((a, b) => b.value.compareTo(a.value));

    return scoredRestaurants.map((e) => e.key).toList();
  }
}
