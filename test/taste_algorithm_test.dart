import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_shi/data/dutch_restaurants_seed.dart';
import 'package:restaurant_shi/models/restaurant.dart';
import 'package:restaurant_shi/models/user_profile.dart';
import 'package:restaurant_shi/services/taste_algorithm_service.dart';

void main() {
  group('TasteAlgorithmService Tests', () {
    const sampleRestaurants = [
      Restaurant(
        id: 'rest_1',
        name: 'Pasta Bella',
        tagline: 'Best Italian Pasta',
        address: 'Damrak 1, Amsterdam',
        city: 'Amsterdam',
        neighborhood: 'Centrum',
        latitude: 52.37,
        longitude: 4.89,
        rating: 4.5,
        reviewCount: 120,
        priceTier: '€€',
        categories: ['Italian', 'Pasta'],
        dietaryTags: ['Vegetarian'],
        photoUrls: ['https://example.com/pasta.jpg'],
        menuItems: [],
        openingHours: '12:00 - 22:00',
        phoneNumber: '+31 20 123 4567',
        websiteUrl: 'https://example.com',
        isSponsored: false,
      ),
      Restaurant(
        id: 'rest_2',
        name: 'Tokyo Ramen',
        tagline: 'Authentic Japanese Noodles',
        address: 'Witte de Withstraat 10, Rotterdam',
        city: 'Rotterdam',
        neighborhood: 'Centrum',
        latitude: 51.91,
        longitude: 4.47,
        rating: 4.8,
        reviewCount: 200,
        priceTier: '€€',
        categories: ['Japanese', 'Asian'],
        dietaryTags: ['Halal'],
        photoUrls: ['https://example.com/ramen.jpg'],
        menuItems: [],
        openingHours: '12:00 - 23:00',
        phoneNumber: '+31 10 987 6543',
        websiteUrl: 'https://example.com',
        isSponsored: false,
      ),
    ];

    test('Filters deck by preferred city', () {
      const user = UserProfile(
        id: 'user_1',
        displayName: 'Tester',
        avatarUrl: 'https://example.com/avatar.jpg',
        friendCode: 'TEST-1234',
        isGuest: true,
      );

      final amsterdamDeck = TasteAlgorithmService.rankDeck(
        allRestaurants: sampleRestaurants,
        user: user,
        preferredCity: 'Amsterdam',
      );

      expect(amsterdamDeck.length, 1);
      expect(amsterdamDeck.first.name, 'Pasta Bella');
    });

    test('Excludes restaurants already swiped by user', () {
      const user = UserProfile(
        id: 'user_2',
        displayName: 'Swiper',
        avatarUrl: 'https://example.com/avatar.jpg',
        friendCode: 'TEST-1234',
        isGuest: true,
        swipeHistory: {'rest_1': 'like'},
      );

      final deck = TasteAlgorithmService.rankDeck(
        allRestaurants: sampleRestaurants,
        user: user,
      );

      expect(deck.length, 1);
      expect(deck.first.id, 'rest_2');
    });

    test('Enforces strict dietary requirements', () {
      const user = UserProfile(
        id: 'user_3',
        displayName: 'Veggie',
        avatarUrl: 'https://example.com/avatar.jpg',
        friendCode: 'TEST-1234',
        isGuest: true,
        dietaryPreferences: ['Vegetarian'],
      );

      final deck = TasteAlgorithmService.rankDeck(
        allRestaurants: sampleRestaurants,
        user: user,
      );

      expect(deck.length, 1);
      expect(deck.first.name, 'Pasta Bella');
    });

    test('Validates complete dataset contains 100+ restaurants with heavy focus on Den Haag', () {
      expect(kDutchRestaurantsSeed.length, greaterThanOrEqualTo(100));
      final denHaagRestaurants = kDutchRestaurantsSeed.where((r) => r.city == 'Den Haag').toList();
      expect(denHaagRestaurants.length, greaterThanOrEqualTo(50));
    });
  });
}
