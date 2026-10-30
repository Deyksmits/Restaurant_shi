import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../theme/app_theme.dart';
import 'restaurant_card.dart';
import 'restaurant_details_sheet.dart';

class TinderSwipeDeck extends StatefulWidget {
  final List<Restaurant> restaurants;
  final Function(Restaurant restaurant) onSwipeLeft;
  final Function(Restaurant restaurant) onSwipeRight;
  final Function(Restaurant restaurant) onSwipeUp;
  final VoidCallback? onDeckEmpty;

  const TinderSwipeDeck({
    super.key,
    required this.restaurants,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onSwipeUp,
    this.onDeckEmpty,
  });

  @override
  State<TinderSwipeDeck> createState() => _TinderSwipeDeckState();
}

class _TinderSwipeDeckState extends State<TinderSwipeDeck> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerSwipe(Offset direction, String type) {
    if (_currentIndex >= widget.restaurants.length) return;
    final currentRestaurant = widget.restaurants[_currentIndex];

    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: direction * 500,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward().then((_) {
      _animController.reset();
      setState(() {
        _dragOffset = Offset.zero;
        _currentIndex++;
      });

      if (type == 'like') {
        widget.onSwipeRight(currentRestaurant);
      } else if (type == 'dislike') {
        widget.onSwipeLeft(currentRestaurant);
      } else if (type == 'superlike') {
        widget.onSwipeUp(currentRestaurant);
      }

      if (_currentIndex >= widget.restaurants.length) {
        widget.onDeckEmpty?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.restaurants.length) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'You\'ve seen all restaurants!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Change your city filter or start a group swiping session with friends.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _currentIndex = 0);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Deck'),
              ),
            ],
          ),
        ),
      );
    }

    final topRestaurant = widget.restaurants[_currentIndex];
    final nextRestaurant = (_currentIndex + 1 < widget.restaurants.length)
        ? widget.restaurants[_currentIndex + 1]
        : null;

    final screenWidth = MediaQuery.of(context).size.width;
    final dragPercent = (_dragOffset.dx / (screenWidth / 2)).clamp(-1.0, 1.0);
    final dragUpPercent = (-_dragOffset.dy / 200).clamp(0.0, 1.0);

    return Column(
      children: [
        // Card Swiping Area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background Card (Peeking underneath)
                if (nextRestaurant != null)
                  Positioned.fill(
                    child: Transform.scale(
                      scale: 0.94 + (dragPercent.abs() * 0.06),
                      child: Opacity(
                        opacity: 0.8 + (dragPercent.abs() * 0.2),
                        child: RestaurantCard(restaurant: nextRestaurant),
                      ),
                    ),
                  ),

                // Top Interactive Draggable Card
                Positioned.fill(
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _dragOffset += details.delta;
                      });
                    },
                    onPanEnd: (details) {
                      final dx = _dragOffset.dx;
                      final dy = _dragOffset.dy;

                      if (dy < -140 && dx.abs() < 100) {
                        _triggerSwipe(const Offset(0, -1.5), 'superlike');
                      } else if (dx > 120) {
                        _triggerSwipe(const Offset(1.5, 0), 'like');
                      } else if (dx < -120) {
                        _triggerSwipe(const Offset(-1.5, 0), 'dislike');
                      } else {
                        // Spring back to center
                        setState(() => _dragOffset = Offset.zero);
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        final currentOffset = _animController.isAnimating
                            ? _slideAnimation.value
                            : _dragOffset;

                        final rotation = (currentOffset.dx / screenWidth) * 0.35;

                        return Transform.translate(
                          offset: currentOffset,
                          child: Transform.rotate(
                            angle: rotation,
                            child: Stack(
                              children: [
                                RestaurantCard(restaurant: topRestaurant),

                                // "LIKE" Stamp (Green)
                                if (dragPercent > 0.15)
                                  Positioned(
                                    top: 40,
                                    left: 30,
                                    child: Transform.rotate(
                                      angle: -0.2,
                                      child: Opacity(
                                        opacity: ((dragPercent - 0.15) / 0.5).clamp(0.0, 1.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: AppColors.accentGreen, width: 4),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'LIKE',
                                            style: TextStyle(
                                              color: AppColors.accentGreen,
                                              fontSize: 32,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                // "NOPE" Stamp (Red)
                                if (dragPercent < -0.15)
                                  Positioned(
                                    top: 40,
                                    right: 30,
                                    child: Transform.rotate(
                                      angle: 0.2,
                                      child: Opacity(
                                        opacity: ((-dragPercent - 0.15) / 0.5).clamp(0.0, 1.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: AppColors.dislikeRed, width: 4),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'NOPE',
                                            style: TextStyle(
                                              color: AppColors.dislikeRed,
                                              fontSize: 32,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                // "SUPER LIKE" Stamp (Blue)
                                if (dragUpPercent > 0.2)
                                  Positioned(
                                    bottom: 120,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Opacity(
                                        opacity: ((dragUpPercent - 0.2) / 0.5).clamp(0.0, 1.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: AppColors.superLikeBlue, width: 4),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'SUPER LIKE',
                                            style: TextStyle(
                                              color: AppColors.superLikeBlue,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Action Buttons
        Padding(
          padding: const EdgeInsets.only(bottom: 14, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1. Dislike (Red Cross)
              _ActionButton(
                icon: Icons.close_rounded,
                color: AppColors.dislikeRed,
                size: 56,
                iconSize: 30,
                onTap: () => _triggerSwipe(const Offset(-1.5, 0), 'dislike'),
              ),

              // 2. Super Like (Blue Star)
              _ActionButton(
                icon: Icons.star_rounded,
                color: AppColors.superLikeBlue,
                size: 50,
                iconSize: 26,
                onTap: () => _triggerSwipe(const Offset(0, -1.5), 'superlike'),
              ),

              // 3. Like (Green Heart)
              _ActionButton(
                icon: Icons.favorite_rounded,
                color: AppColors.accentGreen,
                size: 56,
                iconSize: 30,
                onTap: () => _triggerSwipe(const Offset(1.5, 0), 'like'),
              ),

              // 4. View Menu / Info
              _ActionButton(
                icon: Icons.restaurant_menu,
                color: AppColors.accentGold,
                size: 50,
                iconSize: 24,
                onTap: () => RestaurantDetailsSheet.show(context, topRestaurant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }
}
