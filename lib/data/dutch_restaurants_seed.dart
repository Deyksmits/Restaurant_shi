import '../models/restaurant.dart';
import 'amsterdam_seed.dart';
import 'den_haag_seed.dart';
import 'rotterdam_seed.dart';
import 'utrecht_other_seed.dart';

export 'amsterdam_seed.dart';
export 'den_haag_seed.dart';
export 'rotterdam_seed.dart';
export 'utrecht_other_seed.dart';

/// Complete curated collection of 105 authentic Dutch restaurants,
/// featuring a heavy focus on The Hague (Den Haag: 55 spots),
/// alongside Rotterdam, Amsterdam, Utrecht, Delft, Leiden, and Eindhoven.
final List<Restaurant> kDutchRestaurantsSeed = [
  ...kDenHaagRestaurantsSeed,
  ...kRotterdamRestaurantsSeed,
  ...kAmsterdamRestaurantsSeed,
  ...kUtrechtAndRegionalSeed,
];
