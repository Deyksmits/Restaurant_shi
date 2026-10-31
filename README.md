# 🍽️ TasteMatch (Restaurant Decision App)

A cross-platform mobile application (iOS & Android) built with **Flutter**, **Dart**, and **Riverpod** designed to help friends effortlessly decide where to eat together.

---

## ✨ Features Implemented

* 🔑 **Multi-Provider Authentication & Guest Mode**:
  * Seamless 1-tap Guest onboarding with nickname selection.
  * Apple ID, Google, and Phone Number (`+31` Netherlands default) simulated sign-in.
  * Upgrade guest account anytime from Settings without losing saved data.

* ☁️ **Real-Time Cloud Group Synchronization (Firebase Option 1)**:
  * **Multi-Device Live Sync**: Seamless synchronization across two or more physical iPhones, Android devices, and web browsers.
  * **Kahoot-Style PIN Rooms**: Host creates a room with custom title, date, and city; generates a 6-digit PIN code (e.g. `482 910`).
  * **Live Multiplayer Swiping**: Friends join via PIN over 4G/Wi-Fi; votes are synchronized in real-time.
  * **Instant Match Celebration**: Automatic unanimous (100%) or majority (>50%) matching triggers a synchronized confetti explosion dialog on all connected devices simultaneously!
  * **Dietary Aggregation**: Automatically aggregates allergies & preferences (Vegetarian, Vegan, Halal, Gluten-free) of all room members.

* 🇳🇱 **Curated Authentic Dutch Dataset (105 Hand-Selected Venues)**:
  * **55+ Hotspots in Den Haag (The Hague)**: From Scheveningen Beach & Haven (*Catch by Simonis, Encore, Simonis aan de Haven, Hart Beach, The Shore*) to Hofkwartier & Zeeheldenkwartier (*Bøg, De Twee Heeren, Vincenzo's, Walter Benedict, Bistro Mer, Jamey Bennett, Kua, Takumi Ramen, Garoeda, Poentjak, Warung Mini, Zheng, Basaal*), Chinatown (*Fat Kee, Full Moon City, Little V*), and Binckhorst (*Kompaan Brouwerij, Mama Kelly, Capriole Café*).
  * **50+ Iconic NL Hotspots**: Rotterdam (*Supermercado, Dudok, Kaat Mossel, Hotel New York, Bazar, Ter Marsch & Co*), Amsterdam (*Café de Klos, Blauw, De Kas, Cannibale Royale, Vegan Junk Food Bar, Winkel 43*), Utrecht (*The Streetfood Club, WT Urban Kitchen, LE:EN, Gys*), Delft (*Stads-Koffyhuis, De Kurk*), Leiden (*Lot & de Walvis, Het Pakhuis*), and Eindhoven (*Down Town Gourmet Market, Radio Royaal*).

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

##### Option 1 — Test on iPhone over Local Wi-Fi (Direct, Zero Tools or Accounts Needed!):
As long as your iPhone and Windows PC are connected to the same Wi-Fi network:

1. **Start the Flutter Web Server**:
   ```powershell
   flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080
   ```
2. **Open on your iPhone**:
   * Open **Safari** and enter your PC's local IP address:
     ```text
     http://192.168.2.10:8080
     ```
   * *Pro-tip*: Tap the Safari **Share** icon (square with arrow) → select **"Add to Home Screen"**. It will launch full-screen with native touch swiping and no browser bars!

##### Option 2 — Cloudflare Quick Tunnel (Free, Zero Account / No Signup Needed):
If you want to test outside your home Wi-Fi (e.g. over 4G/5G) without creating any account or API tokens:

1. **Install Cloudflare Tunnel**:
   ```powershell
   winget install Cloudflare.cloudflared
   ```
2. **Start Flutter**:
   ```powershell
   flutter run -d web-server --web-port=8080
   ```
3. **Start the Free Cloudflare Tunnel** (in a separate terminal):
   ```powershell
   cloudflared tunnel --url http://localhost:8080
   ```
   *Cloudflare will print an instant, secure `https://....trycloudflare.com` URL that you can open on any iPhone.*

##### Option 3 — Built-in VS Code Port Forwarding (If using VS Code):
1. Open this repository in VS Code.
2. Run `flutter run -d web-server --web-port=8080`.
3. In VS Code's bottom panel, click the **"Ports"** tab.
4. Click **Forward a Port** → enter `8080`.
5. Right-click the forwarded port → change **Port Visibility** to **Public**.
6. Copy the generated HTTPS link and open it in Safari on your iPhone.

##### Option 4 — Native iOS Build via macOS (Xcode):
1. Open `ios/Runner.xcworkspace` in Xcode on macOS.
2. Select your free personal Apple ID in **Signing & Capabilities**.
3. Run directly on your connected iPhone:
```powershell
flutter run -d ios
```

---

### Step 4: Automated Testing
Run the test suite to verify the recommendation algorithm and matching logic:
```powershell
flutter test
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
