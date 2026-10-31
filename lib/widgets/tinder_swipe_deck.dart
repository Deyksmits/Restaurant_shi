import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/restaurant.dart';
import '../theme/app_theme.dart';
import 'restaurant_card.dart';
import 'restaurant_details_sheet.dart';

class TinderSwipeDeck extends StatefulWidget {
  final List<Restaurant> restaurants;
  final Function(Restaurant restaurant) onSwipeLeft;
  final Function(Restaurant restaurant) onSwipeRight;
  final Function(Restaurant restaurant) onSwipeUp;
  final Function(Restaurant restaurant)? onUndo;
  final VoidCallback? onDeckEmpty;
  final VoidCallback? onResetRequested;

  const TinderSwipeDeck({
    super.key,
    required this.restaurants,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onSwipeUp,
    this.onUndo,
    this.onDeckEmpty,
    this.onResetRequested,
  });

  @override
  State<TinderSwipeDeck> createState() => _TinderSwipeDeckState();
}

class _TinderSwipeDeckState extends State<TinderSwipeDeck>
    with SingleTickerProviderStateMixin {
  late List<Restaurant> _deck;
  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _deck = List<Restaurant>.from(widget.restaurants);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void didUpdateWidget(covariant TinderSwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reset deck if the parent explicitly changed key or if our deck was empty and new items arrived
    if (_deck.isEmpty && widget.restaurants.isNotEmpty) {
      setState(() {
        _deck = List<Restaurant>.from(widget.restaurants);
        _currentIndex = 0;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerSwipe(Offset direction, String type) {
    if (_currentIndex >= _deck.length || _animController.isAnimating) return;
    final currentRestaurant = _deck[_currentIndex];

    HapticFeedback.mediumImpact();

    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: direction * 520,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward().then((_) {
      if (!mounted) return;
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

      if (_currentIndex >= _deck.length) {
        widget.onDeckEmpty?.call();
      }
    });
  }

  void _handleUndo() {
    if (_currentIndex <= 0 || _animController.isAnimating) return;
    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex--;
      _dragOffset = Offset.zero;
    });
    final restored = _deck[_currentIndex];
    widget.onUndo?.call(restored);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _deck.length) {
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
                  Icons.restaurant_rounded,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'You\'ve seen all restaurants in this deck!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Reset your deck, try another city filter, or start a live group session with friends.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_currentIndex > 0) ...[
                    OutlinedButton.icon(
                      onPressed: _handleUndo,
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Undo Last'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onResetRequested?.call();
                      setState(() {
                        if (widget.restaurants.isNotEmpty) {
                          _deck = List<Restaurant>.from(widget.restaurants);
                        }
                        _currentIndex = 0;
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reset Deck'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final topRestaurant = _deck[_currentIndex];
    final nextRestaurant = (_currentIndex + 1 < _deck.length)
        ? _deck[_currentIndex + 1]
        : null;

    final screenWidth = MediaQuery.of(context).size.width;
    final dragPercent = (_dragOffset.dx / (screenWidth / 2)).clamp(-1.0, 1.0);
    final dragUpPercent = (-_dragOffset.dy / 200).clamp(0.0, 1.0);

    return Column(
      children: [
        // Progress & Neighborhood Status Pill
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${topRestaurant.neighborhood}, ${topRestaurant.city}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.chipBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${_deck.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Card Swiping Area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        child: RestaurantCard(
                          key: ValueKey('bg_${nextRestaurant.id}'),
                          restaurant: nextRestaurant,
                        ),
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
                      final vx = details.velocity.pixelsPerSecond.dx;

                      if (dy < -130 && dx.abs() < 110) {
                        _triggerSwipe(const Offset(0, -1.5), 'superlike');
                      } else if (dx > 105 || vx > 700) {
                        _triggerSwipe(const Offset(1.5, 0), 'like');
                      } else if (dx < -105 || vx < -700) {
                        _triggerSwipe(const Offset(-1.5, 0), 'dislike');
                      } else {
                        setState(() => _dragOffset = Offset.zero);
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        final currentOffset = _animController.isAnimating
                            ? _slideAnimation.value
                            : _dragOffset;

                        final rotation =
                            (currentOffset.dx / screenWidth) * 0.32;

                        return Transform.translate(
                          offset: currentOffset,
                          child: Transform.rotate(
                            angle: rotation,
                            child: Stack(
                              children: [
                                RestaurantCard(
                                  key: ValueKey('top_${topRestaurant.id}'),
                                  restaurant: topRestaurant,
                                ),

                                // "LIKE" Stamp (Green)
                                if (dragPercent > 0.15)
                                  Positioned(
                                    top: 40,
                                    left: 30,
                                    child: Transform.rotate(
                                      angle: -0.2,
                                      child: Opacity(
                                        opacity: ((dragPercent - 0.15) / 0.5)
                                            .clamp(0.0, 1.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.25),
                                            border: Border.all(
                                              color: AppColors.accentGreen,
                                              width: 4,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'LEKKER!',
                                            style: TextStyle(
                                              color: AppColors.accentGreen,
                                              fontSize: 30,
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
                                        opacity: ((-dragPercent - 0.15) / 0.5)
                                            .clamp(0.0, 1.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.25),
                                            border: Border.all(
                                              color: AppColors.dislikeRed,
                                              width: 4,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'SKIP',
                                            style: TextStyle(
                                              color: AppColors.dislikeRed,
                                              fontSize: 30,
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
                                        opacity: ((dragUpPercent - 0.2) / 0.5)
                                            .clamp(0.0, 1.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.35),
                                            border: Border.all(
                                              color: AppColors.superLikeBlue,
                                              width: 4,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'SUPER LIKE ⭐',
                                            style: TextStyle(
                                              color: AppColors.superLikeBlue,
                                              fontSize: 26,
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

        // Bottom Action Buttons (5 buttons: Undo, Dislike, Superlike, Like, Menu)
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 2, left: 12, right: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 0. Rewind / Undo
              _ActionButton(
                icon: Icons.replay_rounded,
                color: _currentIndex > 0
                    ? AppColors.textSecondary
                    : Colors.grey.shade300,
                size: 44,
                iconSize: 22,
                tooltip: 'Undo last swipe',
                onTap: _handleUndo,
              ),

              // 1. Dislike (Red Cross)
              _ActionButton(
                icon: Icons.close_rounded,
                color: AppColors.dislikeRed,
                size: 58,
                iconSize: 30,
                tooltip: 'Pass',
                onTap: () => _triggerSwipe(const Offset(-1.5, 0), 'dislike'),
              ),

              // 2. Super Like (Blue Star)
              _ActionButton(
                icon: Icons.star_rounded,
                color: AppColors.superLikeBlue,
                size: 50,
                iconSize: 26,
                tooltip: 'Super Like',
                onTap: () => _triggerSwipe(const Offset(0, -1.5), 'superlike'),
              ),

              // 3. Like (Green Heart)
              _ActionButton(
                icon: Icons.favorite_rounded,
                color: AppColors.accentGreen,
                size: 58,
                iconSize: 30,
                tooltip: 'Like',
                onTap: () => _triggerSwipe(const Offset(1.5, 0), 'like'),
              ),

              // 4. View Menu / Info
              _ActionButton(
                icon: Icons.restaurant_menu_rounded,
                color: AppColors.accentGold,
                size: 44,
                iconSize: 22,
                tooltip: 'Menu & Details',
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
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
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
            border: Border.all(color: color.withOpacity(0.25), width: 1.5),
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}
