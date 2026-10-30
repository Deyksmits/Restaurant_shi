import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/restaurant.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/restaurant_details_sheet.dart';

class FavouritesScreen extends ConsumerStatefulWidget {
  const FavouritesScreen({super.key});

  @override
  ConsumerState<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends ConsumerState<FavouritesScreen> {
  bool _isMapView = false;
  bool _showSuperLikesOnly = false;
  Restaurant? _selectedMapRestaurant;

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoriteRestaurantsProvider);
    final user = ref.watch(authProvider);

    final filteredFavorites = favorites.where((r) {
      if (_showSuperLikesOnly) {
        return user?.superLikeIds.contains(r.id) ?? false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favourites ❤️'),
        actions: [
          // Toggle between List and Map
          IconButton(
            icon: Icon(
              _isMapView ? Icons.view_agenda_outlined : Icons.map_rounded,
              color: AppColors.primary,
            ),
            tooltip: _isMapView ? 'List View' : 'Map View',
            onPressed: () {
              setState(() => _isMapView = !_isMapView);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips (All vs Super Likes)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Liked'),
                  selected: !_showSuperLikesOnly,
                  selectedColor: AppColors.primary.withOpacity(0.18),
                  checkmarkColor: AppColors.primary,
                  onSelected: (val) {
                    setState(() => _showSuperLikesOnly = false);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: AppColors.superLikeBlue, size: 16),
                      SizedBox(width: 4),
                      Text('Super Likes'),
                    ],
                  ),
                  selected: _showSuperLikesOnly,
                  selectedColor: AppColors.superLikeBlue.withOpacity(0.18),
                  checkmarkColor: AppColors.superLikeBlue,
                  onSelected: (val) {
                    setState(() => _showSuperLikesOnly = true);
                  },
                ),
                const Spacer(),
                Text(
                  '${filteredFavorites.length} saved',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Main View (List or Map)
          Expanded(
            child: filteredFavorites.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_border_rounded, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No favourites yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Swipe right on restaurants in the Explore tab to save them here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : _isMapView
                    ? _buildOpenStreetMap(filteredFavorites)
                    : _buildFavouritesList(filteredFavorites),
          ),
        ],
      ),
    );
  }

  // --- List / Grid View ---
  Widget _buildFavouritesList(List<Restaurant> favorites) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final r = favorites[index];
        final user = ref.watch(authProvider);
        final isSuperLike = user?.superLikeIds.contains(r.id) ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            onTap: () => RestaurantDetailsSheet.show(context, r),
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: CachedNetworkImage(
                        imageUrl: r.photoUrls.first,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (isSuperLike)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.superLikeBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'SUPER LIKED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton(
                        icon: const Icon(Icons.favorite, color: AppColors.primary),
                        onPressed: () {
                          ref.read(databaseServiceProvider).toggleFavorite(r.id);
                        },
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              r.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                r.rating.toStringAsFixed(1),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${r.neighborhood}, ${r.city} • ${r.priceTier}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        r.tagline,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 100% Free OpenStreetMap View with Pins ---
  Widget _buildOpenStreetMap(List<Restaurant> favorites) {
    // Default center to Netherlands (e.g. Utrecht / Amsterdam)
    final initialCenter = favorites.isNotEmpty
        ? LatLng(favorites.first.latitude, favorites.first.longitude)
        : const LatLng(52.3676, 4.9041);

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 12.0,
            onTap: (_, __) {
              setState(() => _selectedMapRestaurant = null);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tastematch.nl.app',
            ),
            MarkerLayer(
              markers: favorites.map((r) {
                final isSelected = _selectedMapRestaurant?.id == r.id;

                return Marker(
                  point: LatLng(r.latitude, r.longitude),
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedMapRestaurant = r);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentGold : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: isSelected ? 12 : 6,
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.restaurant, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Bottom Selected Restaurant Preview Card on Map
        if (_selectedMapRestaurant != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: _selectedMapRestaurant!.photoUrls.first,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedMapRestaurant!.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_selectedMapRestaurant!.neighborhood}, ${_selectedMapRestaurant!.city}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${_selectedMapRestaurant!.rating} ⭐',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () => _launchNavigation(_selectedMapRestaurant!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.directions, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Navigate',
                                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _launchNavigation(Restaurant r) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${r.latitude},${r.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
