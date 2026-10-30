# 🍽️ TasteMatch (Restaurant Decision App)

A cross-platform mobile application (iOS & Android) built with **Flutter**, **Dart**, and **Riverpod** designed to help friends effortlessly decide where to eat together.

---

## ✨ Features Implemented

* 🔑 **Multi-Provider Authentication & Guest Mode**:
  * Seamless 1-tap Guest onboarding with nickname selection.
  * Apple ID, Google, and Phone Number (`+31` Netherlands default) simulated sign-in.
  * Upgrade guest account anytime from Settings without losing saved data.

* 🎯 **Kahoot-Style Real-Time Group Swiping**:
  * Host creates a room with custom title, date, and city (Amsterdam, Rotterdam, Utrecht, etc.).
  * Generates a 6-digit PIN code (e.g. `482 910`) and share link.
  * Configurable matching rules: **Unanimous (100% consensus)** or **Majority (>50%)**.
  * Aggregates dietary restrictions (e.g. auto-filters vegetarian spots if any member is vegetarian).
  * Real-time lobby and synchronized swiping with celebratory confetti explosion upon match!

* 🔥 **Tinder-Style Explore Feed**:
  * Fluid swipe cards (drag right to **Like**, left to **Nope**, up to **Super Like**).
  * Story-style photo carousel (tap left/right edges of photos to cycle images).
  * Swipe-up / tap button to view the full menu with prices, dietary tags (🌱 Vegetarian, 🌿 Vegan, 🌾 Gluten-free, 🌙 Halal), and address.
  * **Adaptive Taste Profile Algorithm**: Learns from swipe history to prioritize cuisines you love.

* ❤️ **Favourites & OpenStreetMap View**:
  * Stored liked & super-liked restaurants.
  * Filter by Super Likes ⭐ and categories.
  * **100% Free OpenStreetMap** (`flutter_map`): Interactive map with custom pins, venue popups, and direct navigation links (no Google billing or API keys needed).

* 💼 **Interactive Restaurant Owner & Advertising Portal**:
  * Business partner simulation dashboard.
  * Real-time analytics: Impressions, Right Swipes (Likes), and Group Matches.
  * Venue onboarding form to submit new restaurants and highlight signature dishes. Newly submitted restaurants instantly appear in the Explore deck and Home news feed.

* 🇳🇱 **Curated Authentic Dutch Dataset**:
  * High-res imagery and authentic Dutch menus across Amsterdam, Rotterdam, Utrecht, Den Haag, and Eindhoven (e.g., *Café de Klos*, *Blauw Indonesian Rijsttafel*, *The Streetfood Club*, *Supermercado*, *Dudok*, *Vegan Junk Food Bar*).

---

## 🚀 How to Run the App

### Step 1: Install the Flutter SDK (if not already installed)
On Windows, you can install Flutter in one command using PowerShell:
```powershell
winget install Google.Flutter
```
*Alternatively, download the official Windows Flutter SDK zip from [flutter.dev](https://flutter.dev) and extract it to `C:\flutter`, then add `C:\flutter\bin` to your system PATH.*

Verify your installation:
```powershell
flutter doctor
```

### Step 2: Install Project Dependencies
In this repository directory:
```powershell
flutter pub get
```

### Step 3: Run the App

#### A. Run in Web Browser (Instant Preview):
```powershell
flutter run -d chrome
```

#### B. Run on Android (Physical Device or Emulator):
1. Plug in your Android phone with USB Debugging enabled (or start an Android Emulator).
2. Run:
```powershell
flutter run -d android
```
*(To build a standalone APK to share with friends on WhatsApp or Google Drive: `flutter build apk --split-per-abi`)*

#### C. Run on iOS (iPhone):
1. Open `ios/Runner.xcworkspace` in Xcode on macOS.
2. Select your free personal Apple ID in **Signing & Capabilities**.
3. Run directly on your connected iPhone:
```powershell
flutter run -d ios
```

---

## 📁 Project Architecture

```
lib/
├── data/
│   └── dutch_restaurants_seed.dart   # Authentic NL restaurants, photos, and menus
├── models/
│   ├── group_session.dart            # Kahoot room PIN, members, votes, and matches
│   ├── menu_item.dart                # Dishes, prices, and dietary flags
│   ├── news_item.dart                # Home feed updates and social events
│   ├── restaurant.dart               # Complete venue schema
│   └── user_profile.dart             # Auth, friend code, and swipe history
├── providers/
│   └── app_providers.dart            # Riverpod state notifiers & reactive streams
├── screens/
│   ├── account/
│   │   ├── account_screen.dart       # User profile, friend code, and dietary settings
│   │   └── restaurant_portal_screen.dart # Advertiser dashboard & venue submitter
│   ├── auth/
│   │   └── login_screen.dart         # Guest, Apple, Google, and Phone sign-in
│   ├── explore/
│   │   └── explore_screen.dart       # Tinder swipe feed with city filter
│   ├── favourites/
│   │   └── favourites_screen.dart    # Saved spots + Free OpenStreetMap
│   ├── groups/
│   │   └── groups_screen.dart        # PIN code entry, lobby, and multiplayer swiping
│   ├── home/
│   │   └── home_screen.dart          # News feed, trending spots, and friend requests
│   └── main_shell.dart               # 5-tab persistent bottom navigation
├── services/
│   ├── mock_database_service.dart    # Reactive in-memory DB (swappable to Firebase)
│   └── taste_algorithm_service.dart  # Adaptive swipe recommendation scoring
├── theme/
│   └── app_theme.dart                # Warm Foodie Coral & Modern design system
├── widgets/
│   ├── match_dialog.dart             # Celebratory match modal with confetti
│   ├── restaurant_card.dart          # Tinder card with photo cycling
│   ├── restaurant_details_sheet.dart # Scrollable menu & dietary details drawer
│   └── tinder_swipe_deck.dart        # Drag physics and dynamic stamp overlays
└── main.dart                         # Application entry point
```

---

## 💰 Prototyping Cost
* **Total Cost: €0.00**
* Runs 100% offline or on free cloud tiers. No credit card or paid subscriptions required.
