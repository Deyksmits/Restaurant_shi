import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/menu_item.dart';
import '../../models/restaurant.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';

class RestaurantPortalScreen extends ConsumerStatefulWidget {
  const RestaurantPortalScreen({super.key});

  @override
  ConsumerState<RestaurantPortalScreen> createState() => _RestaurantPortalScreenState();
}

class _RestaurantPortalScreenState extends ConsumerState<RestaurantPortalScreen> {
  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _addressController = TextEditingController();
  final _menuItemNameController = TextEditingController();
  final _menuItemPriceController = TextEditingController();
  String _selectedCity = 'Amsterdam';
  String _selectedPrice = '€€';
  final String _selectedCategory = 'Borrel & Bites';

  bool _isSubmitting = false;

  void _submitPartnerRestaurant() async {
    final name = _nameController.text.trim();
    final tagline = _taglineController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty || tagline.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a restaurant name and tagline.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final newRestaurant = Restaurant(
      id: 'partner_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      tagline: tagline,
      address: address.isNotEmpty ? address : 'Herengracht 120',
      city: _selectedCity,
      neighborhood: 'Centrum',
      latitude: 52.3676,
      longitude: 4.9041,
      photoUrls: [
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1000&q=80',
      ],
      rating: 4.9,
      reviewCount: 42,
      priceTier: _selectedPrice,
      categories: [_selectedCategory, 'Borrel'],
      dietaryTags: ['Vegetarian-friendly'],
      openingHours: 'Mon-Sun: 12:00 - 23:00',
      isSponsored: true,
      sponsoredNote: 'Featured Partner • 10% off for TasteMatch groups!',
      phoneNumber: '+31 20 892 1100',
      websiteUrl: 'https://partnerrestaurant.nl',
      menuItems: [
        MenuItem(
          id: 'item_p_1',
          name: _menuItemNameController.text.isNotEmpty
              ? _menuItemNameController.text.trim()
              : 'House Special Tasting Platter',
          description: 'Curated selection of chef specialty bites and seasonal dips',
          price: double.tryParse(_menuItemPriceController.text.trim()) ?? 18.50,
          category: 'Mains',
        ),
      ],
    );

    await ref.read(advertiserProvider.notifier).registerNewVenue(newRestaurant);

    setState(() => _isSubmitting = false);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🎉 Restaurant Listed!'),
        content: Text(
          '${newRestaurant.name} is now promoted as a featured partner. Users can swipe on it in the Explore deck, and it is featured on the Home news feed!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('View in App'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final advertiserState = ref.watch(advertiserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Partner Portal 💼'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1F2937), Color(0xFF111827)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights_rounded, color: AppColors.accentGold, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Promote to Hungry Groups',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Reach groups of friends at the exact moment they are deciding where to dine.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Analytics Dashboard Metrics
          const Text(
            'Partner Live Analytics (30 Days)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildMetricCard(
                label: 'Impressions',
                value: advertiserState.totalImpressions.toString(),
                icon: Icons.visibility_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                label: 'Right Swipes (Likes)',
                value: advertiserState.totalRightSwipes.toString(),
                icon: Icons.favorite_rounded,
                color: AppColors.accentGreen,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                label: 'Group Matches',
                value: advertiserState.totalGroupMatches.toString(),
                icon: Icons.celebration_rounded,
                color: AppColors.accentGold,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Partner Venue Onboarding Form
          const Text(
            'List or Advertise Your Venue',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Restaurant Name',
                    hintText: 'e.g. Café de Brouwerij',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _taglineController,
                  decoration: const InputDecoration(
                    labelText: 'Promotional Tagline / Catchphrase',
                    hintText: 'e.g. Best artisanal burgers and craft beer terrace',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Amsterdam', 'Rotterdam', 'Utrecht', 'Den Haag', 'Eindhoven']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCity = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPrice,
                        decoration: const InputDecoration(
                          labelText: 'Price Tier',
                          border: OutlineInputBorder(),
                        ),
                        items: ['€', '€€', '€€€', '€€€€']
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPrice = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Street Address',
                    hintText: 'e.g. Prinsengracht 450',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Signature Menu Item to Highlight',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _menuItemNameController,
                        decoration: const InputDecoration(
                          labelText: 'Dish Name',
                          hintText: 'Truffle Smash Burger',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _menuItemPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixText: '€',
                          labelText: 'Price',
                          hintText: '16.50',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitPartnerRestaurant,
                  icon: const Icon(Icons.rocket_launch_rounded),
                  label: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Publish & Launch Sponsored Card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
