import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/restaurant.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

class RestaurantDetailsSheet extends ConsumerStatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailsSheet({super.key, required this.restaurant});

  static void show(BuildContext context, Restaurant restaurant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RestaurantDetailsSheet(restaurant: restaurant),
    );
  }

  @override
  ConsumerState<RestaurantDetailsSheet> createState() =>
      _RestaurantDetailsSheetState();
}

class _RestaurantDetailsSheetState
    extends ConsumerState<RestaurantDetailsSheet> {
  int _selectedPhotoIdx = 0;

  Future<void> _openMapsNavigation(Restaurant r) async {
    HapticFeedback.lightImpact();
    final query = Uri.encodeComponent('${r.name}, ${r.neighborhood}, ${r.city}');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query&query_place_id=${r.latitude},${r.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareRestaurant(Restaurant r) {
    HapticFeedback.lightImpact();
    Share.share(
      '🍽️ Check out ${r.name} in ${r.neighborhood}, ${r.city} (${r.rating}⭐ • ${r.priceTier})!\n"${r.tagline}"\nGevonden via TasteMatch NL 🎯',
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    final user = ref.watch(authProvider);
    final isFavorite = user?.favoriteIds.contains(restaurant.id) ?? false;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  children: [
                    // 1. Photo Gallery Carousel
                    if (restaurant.photoUrls.isNotEmpty) ...[
                      SizedBox(
                        height: 210,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: PageView.builder(
                                itemCount: restaurant.photoUrls.length,
                                onPageChanged: (idx) {
                                  setState(() => _selectedPhotoIdx = idx);
                                },
                                itemBuilder: (context, idx) {
                                  return CachedNetworkImage(
                                    imageUrl: restaurant.photoUrls[idx],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (ctx, url) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    errorWidget: (ctx, url, err) => Container(
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.restaurant, size: 48),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Top-right favorite button
                            Positioned(
                              top: 12,
                              right: 12,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  ref
                                      .read(databaseServiceProvider)
                                      .toggleFavorite(restaurant.id);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isFavorite
                                        ? AppColors.primary
                                        : Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            // Page indicator dots
                            if (restaurant.photoUrls.length > 1)
                              Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    restaurant.photoUrls.length,
                                    (idx) => Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      width: _selectedPhotoIdx == idx ? 18 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _selectedPhotoIdx == idx
                                            ? Colors.white
                                            : Colors.white54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 2. Restaurant Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurant.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                restaurant.tagline,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.accentGold,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 3. Quick Action Buttons (Route, Share, Save)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openMapsNavigation(restaurant),
                            icon: const Icon(Icons.directions_rounded, size: 18),
                            label: const Text('Route'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _shareRestaurant(restaurant),
                            icon: const Icon(Icons.ios_share_rounded, size: 18),
                            label: const Text('Share'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(databaseServiceProvider)
                                  .toggleFavorite(restaurant.id);
                            },
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 18,
                            ),
                            label: Text(isFavorite ? 'Saved' : 'Save'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 4. Quick Info Pills
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(
                            Icons.euro_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: Text('Price: ${restaurant.priceTier}'),
                        ),
                        Chip(
                          avatar: const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            '${restaurant.neighborhood}, ${restaurant.city}',
                          ),
                        ),
                        Chip(
                          avatar: const Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: AppColors.accentGreen,
                          ),
                          label: Text(restaurant.openingHours),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Categories & Dietary Options
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...restaurant.categories.map((cat) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '🍴 $cat',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }),
                        ...restaurant.dietaryTags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.accentGreen.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '🌱 $tag',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentGreen,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 10),

                    // 5. Signature Menu Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Signature Menu & Borrel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${restaurant.menuItems.length} highlights',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Menu items list
                    ...restaurant.menuItems.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (item.isVegetarian) ...[
                                        const SizedBox(width: 6),
                                        const Text(
                                          '🌱',
                                          semanticsLabel: 'Vegetarian',
                                        ),
                                      ],
                                      if (item.isHalal) ...[
                                        const SizedBox(width: 4),
                                        const Text('🌙', semanticsLabel: 'Halal'),
                                      ],
                                      if (item.isGlutenFree) ...[
                                        const SizedBox(width: 4),
                                        const Text(
                                          '🌾',
                                          semanticsLabel: 'Gluten Free',
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.category,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '€${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // 6. Embedded OpenStreetMap Location Preview
                    const Text(
                      'Location & Neighborhood Map',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 170,
                        child: Stack(
                          children: [
                            FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(
                                  restaurant.latitude,
                                  restaurant.longitude,
                                ),
                                initialZoom: 14.5,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'nl.tastematch.app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(
                                        restaurant.latitude,
                                        restaurant.longitude,
                                      ),
                                      width: 46,
                                      height: 46,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.restaurant_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _openMapsNavigation(restaurant),
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Open in Maps',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
