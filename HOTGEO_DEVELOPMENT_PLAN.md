# HotGeo Flutter Prototype - Complete Development Plan

**Game Concept:** Daily geography guessing game with Indiana Jones nostalgic aesthetic
**Platform:** Flutter (Android, iOS, Web)
**Timeline:** 13 days part-time (~26 hours) MVP + 5 days cross-platform
**Cost:** $0 (100% free tech stack)
**Distribution:** Open Source (MIT License)

---

## Table of Contents

1. [Flutter Setup & Dependencies](#1-flutter-setup--dependencies)
2. [Map Solution](#2-map-solution)
3. [Project Structure](#3-project-structure)
4. [Core Features - Build Order](#4-core-features---build-order)
5. [Hot/Cold Feedback System](#5-hotcold-feedback-system)
6. [Daily Challenge Storage](#6-daily-challenge-storage)
7. [UI/UX Implementation](#7-uiux-implementation)
8. [Testing Strategy](#8-testing-strategy)
9. [Timeline & Complexity](#9-timeline--complexity)
10. [First Day Setup](#10-first-day-setup)
11. [Technical Risks & Mitigations](#11-technical-risks--mitigations)
12. [Success Metrics](#12-success-metrics)
13. [Open Source Strategy](#13-open-source-strategy) ⭐ NEW
14. [Cross-Platform Sync & Accounts](#14-cross-platform-sync--accounts) ⭐ NEW
15. [Web Deployment](#15-web-deployment) ⭐ NEW

---

## 1. Flutter Setup & Dependencies

### Initial Setup Commands

```bash
# Check Flutter installation
flutter doctor

# Create Flutter project
cd /Users/10381054/code/personal/hotgeo
flutter create --platforms=android,ios hotgeo
cd hotgeo

# Test on Android device
flutter run
```

### Required Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Map rendering (FREE, OpenStreetMap-based)
  flutter_map: ^6.1.0
  latlong2: ^0.9.0

  # HTTP requests for map tiles
  http: ^1.1.0

  # State management (simple, built-in)
  provider: ^6.1.1

  # Local storage for daily challenges
  shared_preferences: ^2.2.2

  # Share results functionality
  share_plus: ^7.2.1

  # Custom fonts for vintage aesthetic
  google_fonts: ^6.1.0

  # Date utilities
  intl: ^0.18.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

**Estimated Setup Time:** 1-2 hours

---

## 2. Map Solution

### Selected: flutter_map + OpenStreetMap (100% FREE)

**Why this is the best choice:**
- Completely free, no API keys or limits
- Excellent Flutter integration
- Smooth zooming/panning on mobile
- Multiple tile providers available
- Can style for vintage aesthetic

**Alternative Tile Providers (all free):**
1. **OpenStreetMap Standard** - Default, clean
2. **OpenTopoMap** - Topographic (more adventurous feel)
3. **Stamen Watercolor** - Artistic, vintage-friendly
4. **Custom Sepia Filter** - Apply aged parchment overlay

**Cost Comparison:**
- flutter_map + OSM: **$0/month** ✅
- Google Maps: $200/month credit, then $7 per 1000 requests ❌
- Mapbox: 50k free requests/month, then $5 per 1000 ❌

---

## 3. Project Structure

```
hotgeo/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── models/
│   │   ├── game_state.dart                # Current game state
│   │   ├── daily_challenge.dart           # Challenge data model
│   │   └── guess_result.dart              # Guess feedback data
│   ├── services/
│   │   ├── challenge_service.dart         # Generate/fetch daily challenges
│   │   ├── distance_calculator.dart       # Haversine distance calculation
│   │   └── storage_service.dart           # SharedPreferences wrapper
│   ├── screens/
│   │   ├── splash_screen.dart             # Opening animation
│   │   ├── game_screen.dart               # Main game UI
│   │   └── results_screen.dart            # Win/lose + share
│   ├── widgets/
│   │   ├── vintage_map.dart               # Map with parchment overlay
│   │   ├── compass_rose.dart              # Directional indicator
│   │   ├── attempt_tracker.dart           # Visual guess counter
│   │   ├── feedback_banner.dart           # "Getting warmer!" messages
│   │   └── share_card.dart                # Emoji grid generator
│   ├── theme/
│   │   ├── app_colors.dart                # Indiana Jones palette
│   │   ├── app_text_styles.dart           # Vintage typography
│   │   └── decorations.dart               # Parchment borders, etc.
│   ├── utils/
│   │   ├── constants.dart                 # Game rules (6 attempts, etc.)
│   │   └── emoji_generator.dart           # Convert results to emojis
│   └── data/
│       └── challenges_2025.dart           # Hardcoded daily challenges
├── assets/
│   ├── images/
│   │   ├── compass_rose.png               # Directional overlay
│   │   ├── parchment_texture.png          # Map overlay
│   │   └── leather_border.png             # UI frames
│   └── fonts/
│       └── IMFellEnglish/                 # Vintage font (Google Fonts)
└── test/
    ├── distance_calculator_test.dart
    └── challenge_service_test.dart
```

---

## 4. Core Features - Build Order

### Phase 1: Basic Infrastructure (3-4 days)

**Files to create:**
1. `lib/theme/app_colors.dart` - Color palette
2. `lib/theme/app_text_styles.dart` - Typography
3. `lib/models/daily_challenge.dart` - Data structure
4. `lib/services/challenge_service.dart` - Hardcoded challenges
5. `lib/screens/game_screen.dart` - Basic scaffold

**Deliverable:** App opens with Indiana Jones theme, shows hardcoded location

**Testing:** Visual inspection, theme consistency

---

### Phase 2: Interactive Map (2-3 days)

**Files to create:**
1. `lib/widgets/vintage_map.dart` - flutter_map integration
2. `lib/services/distance_calculator.dart` - Haversine formula
3. `lib/models/guess_result.dart` - Distance + feedback

**Key Implementation:**

```dart
// distance_calculator.dart
class DistanceCalculator {
  // Returns distance in kilometers using Haversine formula
  static double calculate(LatLng point1, LatLng point2) {
    const R = 6371.0; // Earth radius in km

    final dLat = _toRadians(point2.latitude - point1.latitude);
    final dLng = _toRadians(point2.longitude - point1.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(point1.latitude)) *
        cos(_toRadians(point2.latitude)) *
        sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  static String getFeedback(double distanceKm, int attemptNumber) {
    if (distanceKm < 50) return "🔥 Almost there, explorer!";
    if (distanceKm < 200) return "♨️ You're getting warmer!";
    if (distanceKm < 500) return "🌡️ Still a ways to go...";
    return "❄️ Cold as the Arctic, adventurer!";
  }
}
```

**Deliverable:** Tap map, see distance feedback

**Testing:** Test known locations (e.g., NYC to LA = ~3,944 km)

---

### Phase 3: Game Logic (2 days)

**Files to create:**
1. `lib/models/game_state.dart` - State management
2. `lib/widgets/attempt_tracker.dart` - Visual counter
3. `lib/widgets/feedback_banner.dart` - Messages

**Key State Management:**

```dart
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class GameState extends ChangeNotifier {
  int attemptsRemaining = 6;
  List<GuessResult> guesses = [];
  bool gameWon = false;
  bool gameLost = false;
  LatLng? targetLocation;

  void initialize(LatLng target) {
    targetLocation = target;
    attemptsRemaining = 6;
    guesses.clear();
    gameWon = false;
    gameLost = false;
    notifyListeners();
  }

  void makeGuess(LatLng guess) {
    if (targetLocation == null || gameWon || gameLost) return;

    double distance = DistanceCalculator.calculate(guess, targetLocation!);

    guesses.add(GuessResult(
      location: guess,
      distance: distance,
      attemptNumber: 7 - attemptsRemaining,
    ));

    attemptsRemaining--;

    // Win threshold: 25km
    if (distance < 25) {
      gameWon = true;
    }

    if (attemptsRemaining == 0 && !gameWon) {
      gameLost = true;
    }

    notifyListeners();
  }

  void reset() {
    attemptsRemaining = 6;
    guesses.clear();
    gameWon = false;
    gameLost = false;
    targetLocation = null;
    notifyListeners();
  }
}
```

**Deliverable:** Full game loop (6 attempts → win/lose)

**Testing:** Play through complete games, test edge cases

---

### Phase 4: Daily Challenge System (1-2 days)

**Files to create:**
1. `lib/services/storage_service.dart` - Persistent storage
2. `lib/data/challenges_2025.dart` - 365 hardcoded challenges
3. Updated `challenge_service.dart` - Date-based selection

**Simple Daily System (MVP):**

```dart
import 'package:latlong2/latlong.dart';

class DailyChallenge {
  final DateTime date;
  final LatLng target;
  final String hint;
  final String region;
  final String difficulty;

  DailyChallenge({
    required this.date,
    required this.target,
    required this.hint,
    required this.region,
    required this.difficulty,
  });
}

class ChallengeService {
  // Hardcoded list of 365 challenges
  static final List<DailyChallenge> challenges = [
    DailyChallenge(
      date: DateTime(2025, 1, 1),
      target: LatLng(48.8584, 2.2945), // Eiffel Tower
      hint: "The City of Light",
      region: "Europe",
      difficulty: "easy",
    ),
    DailyChallenge(
      date: DateTime(2025, 1, 2),
      target: LatLng(27.1751, 78.0421), // Taj Mahal
      hint: "A monument to eternal love",
      region: "Asia",
      difficulty: "medium",
    ),
    // ... 363 more
  ];

  static DailyChallenge getTodaysChallenge() {
    DateTime today = DateTime.now();
    // Calculate days since epoch
    int dayOfYear = today.difference(DateTime(2025, 1, 1)).inDays;
    // Loop through challenges
    return challenges[dayOfYear % challenges.length];
  }
}
```

**Storage Logic:**

```dart
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String LAST_PLAYED_DATE = 'last_played_date';
  static const String TODAYS_GUESSES = 'todays_guesses';
  static const String TODAYS_RESULT = 'todays_result';
  static const String TOTAL_WINS = 'total_wins';
  static const String TOTAL_LOSSES = 'total_losses';
  static const String WIN_STREAK = 'win_streak';

  // Only allow one play per day
  static Future<bool> hasPlayedToday() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastPlayed = prefs.getString(LAST_PLAYED_DATE);
    String today = DateTime.now().toIso8601String().split('T')[0];
    return lastPlayed == today;
  }

  static Future<void> markPlayedToday() async {
    final prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString(LAST_PLAYED_DATE, today);
  }

  static Future<void> saveGameResult(bool won, int attempts) async {
    final prefs = await SharedPreferences.getInstance();

    // Update stats
    int totalWins = prefs.getInt(TOTAL_WINS) ?? 0;
    int totalLosses = prefs.getInt(TOTAL_LOSSES) ?? 0;
    int winStreak = prefs.getInt(WIN_STREAK) ?? 0;

    if (won) {
      await prefs.setInt(TOTAL_WINS, totalWins + 1);
      await prefs.setInt(WIN_STREAK, winStreak + 1);
    } else {
      await prefs.setInt(TOTAL_LOSSES, totalLosses + 1);
      await prefs.setInt(WIN_STREAK, 0);
    }

    await markPlayedToday();
  }
}
```

**Deliverable:** New challenge each day, prevents multiple plays

**Testing:** Change device date, verify new challenges appear

---

### Phase 5: Hot/Cold + Directional Hints (1-2 days)

**Progressive Hint System:**

```dart
import 'dart:math';
import 'package:latlong2/latlong.dart';

class HintSystem {
  static String getHint(int attemptNumber, LatLng guess, LatLng target) {
    double distance = DistanceCalculator.calculate(guess, target);

    // Attempts 1-3: Temperature only
    if (attemptNumber <= 3) {
      return _getTemperatureHint(distance);
    }

    // Attempts 4-6: Temperature + direction
    String temp = _getTemperatureHint(distance);
    String direction = _getDirectionHint(guess, target);
    return "$temp Head $direction!";
  }

  static String _getTemperatureHint(double distanceKm) {
    if (distanceKm < 50) return "🔥 You're practically there, explorer!";
    if (distanceKm < 200) return "♨️ You're getting warmer, adventurer!";
    if (distanceKm < 500) return "🌡️ Still a ways to go...";
    if (distanceKm < 1000) return "🧊 You're still far from the mark...";
    return "❄️ Cold as the Arctic, explorer!";
  }

  static String _getDirectionHint(LatLng from, LatLng to) {
    double bearing = _calculateBearing(from, to);

    if (bearing < 22.5 || bearing >= 337.5) return "North ⬆️";
    if (bearing < 67.5) return "Northeast ↗️";
    if (bearing < 112.5) return "East ➡️";
    if (bearing < 157.5) return "Southeast ↘️";
    if (bearing < 202.5) return "South ⬇️";
    if (bearing < 247.5) return "Southwest ↙️";
    if (bearing < 292.5) return "West ⬅️";
    return "Northwest ↖️";
  }

  static double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);
    final dLng = _toRadians(to.longitude - from.longitude);

    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) -
        sin(lat1) * cos(lat2) * cos(dLng);

    final bearing = atan2(y, x);
    return (bearing * 180 / pi + 360) % 360;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
```

**Visual Enhancement:** Add compass rose widget that rotates toward target after attempt 3

**Deliverable:** Progressively helpful hints

**Testing:** Test all compass directions, verify accuracy

---

### Phase 6: Share Results (1 day)

**Emoji Grid System:**

```dart
class EmojiGenerator {
  static String generateGrid(List<GuessResult> guesses, bool won) {
    DateTime today = DateTime.now();
    int dayNumber = today.difference(DateTime(2025, 1, 1)).inDays + 1;

    StringBuffer grid = StringBuffer("HotGeo #$dayNumber\n\n");

    for (var guess in guesses) {
      grid.write(_getEmoji(guess.distance));
    }

    grid.write("\n");

    if (won) {
      grid.write("🏆 Expedition successful!");
    } else {
      grid.write("💀 Lost in the wilderness...");
    }

    grid.write("\n\nPlay at: [app link]");

    return grid.toString();
  }

  static String _getEmoji(double distanceKm) {
    if (distanceKm < 50) return "🔥";
    if (distanceKm < 200) return "♨️";
    if (distanceKm < 500) return "🌡️";
    if (distanceKm < 1000) return "🧊";
    return "❄️";
  }
}
```

**Example Output:**
```
HotGeo #327

❄️🧊🌡️♨️🔥🔥
🏆 Expedition successful!

Play at: [app link]
```

**Implementation:**

```dart
import 'package:share_plus/share_plus.dart';

void shareResults(List<GuessResult> guesses, bool won) {
  String shareText = EmojiGenerator.generateGrid(guesses, won);
  Share.share(shareText);
}
```

**Deliverable:** Tap share button → system share dialog

**Testing:** Share to notes/messages, verify formatting

---

## 5. Hot/Cold Feedback System

### Distance Thresholds

```dart
class FeedbackThresholds {
  static const double VICTORY = 25.0;      // Win condition (km)
  static const double BURNING = 50.0;      // 🔥 You're there!
  static const double HOT = 200.0;         // ♨️ Very close
  static const double WARM = 500.0;        // 🌡️ Getting warmer
  static const double COOL = 1000.0;       // 🧊 Still far
  static const double COLD = double.infinity; // ❄️ Very far
}
```

### Feedback Messages (Explorer Theme)

```dart
static const Map<String, List<String>> FEEDBACK_PHRASES = {
  'burning': [
    "🔥 You're practically there, explorer!",
    "🔥 X marks the spot! Just ahead!",
    "🔥 The treasure is within reach!",
  ],
  'hot': [
    "♨️ You're getting warmer, adventurer!",
    "♨️ The trail is heating up!",
    "♨️ Your instincts are guiding you well!",
  ],
  'warm': [
    "🌡️ You're on the right path...",
    "🌡️ Keep exploring this region!",
    "🌡️ Still a ways to go, but don't give up!",
  ],
  'cool': [
    "🧊 You're still far from the mark...",
    "🧊 This territory is unfamiliar...",
    "🧊 Perhaps reconsider your route?",
  ],
  'cold': [
    "❄️ Cold as the Arctic, explorer!",
    "❄️ You've wandered far from the path!",
    "❄️ The compass suggests another direction!",
  ],
};
```

### Visual Feedback

- **Color-coded map markers:** Red (burning) → Blue (cold)
- **Animated feedback banner:** Slides down from top with emoji + text
- **Compass rose:** Appears/rotates after attempt 3
- **Distance display:** Optional numeric distance for debugging

---

## 6. Daily Challenge Storage

### SharedPreferences Schema

```dart
const String LAST_PLAYED_DATE = 'last_played_date';       // "2025-01-15"
const String TODAYS_GUESSES = 'todays_guesses';           // JSON array
const String TODAYS_RESULT = 'todays_result';             // "won" | "lost" | "ongoing"
const String TOTAL_WINS = 'total_wins';                   // Integer
const String TOTAL_LOSSES = 'total_losses';               // Integer
const String WIN_STREAK = 'win_streak';                   // Integer
const String BEST_STREAK = 'best_streak';                 // Integer
const String GAMES_PLAYED = 'games_played';               // Integer
```

### Challenge Selection Algorithm

```dart
static DailyChallenge getTodaysChallenge() {
  DateTime today = DateTime.now().toUtc();
  DateTime epoch = DateTime.utc(2025, 1, 1);

  // Calculate day number since epoch
  int daysSinceEpoch = today.difference(epoch).inDays;

  // Select challenge (loops after 365 days)
  int challengeIndex = daysSinceEpoch % challenges.length;

  return challenges[challengeIndex];
}
```

### Post-MVP: Backend API Option

For dynamic challenges without app updates:

**Option A: Firebase Firestore**
- Free tier: 50k reads/day
- Document structure: `challenges/{YYYY-MM-DD}`
- Fields: `target`, `hint`, `region`, `difficulty`

**Option B: Simple JSON API**
- Host static JSON on GitHub Pages
- Daily cron updates file
- App fetches once per day, caches locally

---

## 7. UI/UX Implementation

### Color Palette

```dart
// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Base palette (Indiana Jones theme)
  static const Color parchment = Color(0xFFF4E8D0);
  static const Color parchmentDark = Color(0xFFE8D7B8);
  static const Color leatherBrown = Color(0xFF3D2817);
  static const Color leatherLight = Color(0xFF5C4033);
  static const Color fadedMapBlue = Color(0xFF7FA99B);
  static const Color oceanBlue = Color(0xFFA8C5BA);
  static const Color weatheredGold = Color(0xFFC9A961);
  static const Color vintageGold = Color(0xFF8B7355);

  // Feedback colors (hot/cold gradient)
  static const Color burning = Color(0xFFFF4500);
  static const Color hot = Color(0xFFFF8C00);
  static const Color warm = Color(0xFFFFD700);
  static const Color cool = Color(0xFF4682B4);
  static const Color cold = Color(0xFF1E90FF);

  // UI accents
  static const Color textPrimary = Color(0xFF2C1810);
  static const Color textSecondary = Color(0xFF5C4033);
  static const Color buttonBorder = Color(0xFF8B7355);
}
```

### Typography

```dart
// lib/theme/app_text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Headings
  static TextStyle title = GoogleFonts.imFellEnglish(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.leatherBrown,
    shadows: [
      Shadow(
        color: AppColors.weatheredGold.withOpacity(0.3),
        blurRadius: 2,
        offset: Offset(1, 1),
      ),
    ],
  );

  static TextStyle subtitle = GoogleFonts.cinzel(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.leatherLight,
  );

  // Body text
  static TextStyle body = GoogleFonts.lora(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySecondary = GoogleFonts.lora(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  // Feedback messages
  static TextStyle feedback = GoogleFonts.imFellEnglish(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.fadedMapBlue,
  );

  // Button text
  static TextStyle button = GoogleFonts.cinzel(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.parchment,
    letterSpacing: 1.2,
  );
}
```

### Game Screen Layout

```
┌─────────────────────────────────┐
│  ⚔️ Today's Expedition          │ ← Vintage header bar
│  The City of Light              │ ← Hint text
├─────────────────────────────────┤
│                                 │
│                                 │
│      [VINTAGE MAP]              │ ← Map with parchment overlay
│      with tap zones             │    Zoom controls in corners
│                                 │
│                                 │
├─────────────────────────────────┤
│  Attempts: ⭕⭕⭕⚪⚪⚪        │ ← Visual attempt tracker
├─────────────────────────────────┤
│  🔥 Almost there, explorer!     │ ← Animated feedback banner
├─────────────────────────────────┤
│    [📤 Share] [📊 Stats]        │ ← Action buttons (leather style)
└─────────────────────────────────┘
```

### Key UI Widgets

**1. Vintage Map Widget**

```dart
class VintageMap extends StatelessWidget {
  final LatLng initialCenter;
  final Function(LatLng) onTap;
  final List<LatLng> guessMarkers;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base map
        FlutterMap(
          options: MapOptions(
            center: initialCenter,
            zoom: 3.0,
            minZoom: 2.0,
            maxZoom: 10.0,
            onTap: (tapPosition, point) => onTap(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.hotgeo.app',
              tileBuilder: _applyVintageFilter,
            ),
            // Guess markers
            MarkerLayer(
              markers: guessMarkers.map((pos) => Marker(
                point: pos,
                builder: (ctx) => Icon(
                  Icons.place,
                  color: Colors.red,
                  size: 40,
                ),
              )).toList(),
            ),
          ],
        ),

        // Parchment texture overlay
        IgnorePointer(
          child: Image.asset(
            'assets/images/parchment_texture.png',
            fit: BoxFit.cover,
            color: AppColors.parchment.withOpacity(0.2),
            colorBlendMode: BlendMode.overlay,
          ),
        ),

        // Worn edges (optional)
        IgnorePointer(
          child: CustomPaint(
            painter: WornEdgesPainter(),
            child: Container(),
          ),
        ),
      ],
    );
  }

  Widget _applyVintageFilter(BuildContext context, Widget tileWidget) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        AppColors.parchmentDark.withOpacity(0.15),
        BlendMode.overlay,
      ),
      child: tileWidget,
    );
  }
}
```

**2. Attempt Tracker Widget**

```dart
class AttemptTracker extends StatelessWidget {
  final int attemptsRemaining;
  final int totalAttempts = 6;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalAttempts, (index) {
        bool used = index < (totalAttempts - attemptsRemaining);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            used ? Icons.cancel : Icons.circle_outlined,
            color: used ? AppColors.leatherBrown : AppColors.weatheredGold,
            size: 24,
          ),
        );
      }),
    );
  }
}
```

**3. Feedback Banner Widget**

```dart
class FeedbackBanner extends StatelessWidget {
  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.parchmentDark,
        border: Border.all(color: AppColors.buttonBorder, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message,
        style: AppTextStyles.feedback,
        textAlign: TextAlign.center,
      ),
    );
  }
}
```

### Animations

1. **Screen transitions:** Page curl effect (or simple fade)
2. **Marker placement:** "Stamp" down animation with scale + rotation
3. **Compass rose:** Smooth rotation with easing when showing direction
4. **Feedback banner:** Slide down from top with bounce effect
5. **Win/lose screen:** Fade in with scale animation

---

## 8. Testing Strategy

### Development Setup

```bash
# Enable USB debugging on Android phone:
# Settings → About Phone → Tap "Build Number" 7 times
# Settings → Developer Options → Enable "USB Debugging"

# Connect phone via USB
adb devices

# Run app on connected device
flutter run

# Hot reload during development (press 'r' in terminal)
# Hot restart (press 'R' in terminal)

# Build release APK for testing
flutter build apk --release
```

### Test Checklist

#### Phase 1 - Basic Functionality
- [ ] App launches without crashes
- [ ] Theme colors display correctly (parchment background, leather brown text)
- [ ] Fonts load properly (IM Fell English, Cinzel)
- [ ] Navigation works (if multiple screens)

#### Phase 2 - Map Functionality
- [ ] Map loads and renders tiles
- [ ] Map zooms in/out smoothly (pinch gesture)
- [ ] Map pans without lag (drag gesture)
- [ ] Tap registers correctly at tapped coordinates
- [ ] Test 20+ taps in different locations
- [ ] Zoom to min/max levels doesn't crash

#### Phase 3 - Game Logic
- [ ] Distance calculation is accurate (test NYC → LA = ~3,944 km)
- [ ] Attempt counter decrements correctly (6 → 5 → ... → 0)
- [ ] Win condition triggers at <25km
- [ ] Lose condition triggers after 6 failed attempts
- [ ] Game state persists when app backgrounds/resumes
- [ ] Cannot make guesses after game ends

#### Phase 4 - Daily Challenge
- [ ] Only one game allowed per day
- [ ] Trying to play again shows "completed" screen
- [ ] New challenge appears at midnight (test by changing device time)
- [ ] Progress saved if app closes mid-game
- [ ] Stats persist across app restarts
- [ ] Win/loss counts increment correctly

#### Phase 5 - Hints & Feedback
- [ ] Hot/cold feedback displays correctly
- [ ] Temperature emoji matches distance (🔥 < 50km, ❄️ > 1000km)
- [ ] Directional hints appear after attempt 3
- [ ] Compass directions are accurate (test all 8 directions)
- [ ] Feedback banner animates smoothly
- [ ] Messages rotate/vary (not always same phrase)

#### Phase 6 - Share Functionality
- [ ] Share button appears after game ends
- [ ] Emoji grid generates correctly
- [ ] Share dialog opens system share sheet
- [ ] Text formats correctly in Messages, Notes, etc.
- [ ] Day number increments daily

#### Phase 7 - Performance
- [ ] App launches in <3 seconds
- [ ] No frame drops during map interaction (60fps)
- [ ] Memory usage stays below 200MB
- [ ] Battery drain is minimal (<5% per game)
- [ ] Map tiles cache properly (works offline after first load)

#### Phase 8 - Edge Cases
- [ ] No internet: App loads with cached tiles or shows error
- [ ] Screen rotation: UI adapts correctly (portrait/landscape)
- [ ] App interruptions: Phone call, notification, multitask
- [ ] Invalid date on device: Handles gracefully
- [ ] Storage full: Doesn't crash when saving
- [ ] First time user: Tutorial or onboarding works

### Automated Tests

```dart
// test/distance_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:hotgeo/services/distance_calculator.dart';

void main() {
  group('DistanceCalculator', () {
    test('calculates NYC to LA distance correctly', () {
      final nyc = LatLng(40.7128, -74.0060);
      final la = LatLng(34.0522, -118.2437);
      final distance = DistanceCalculator.calculate(nyc, la);

      // Should be approximately 3,944 km
      expect(distance, greaterThan(3900));
      expect(distance, lessThan(4000));
    });

    test('win condition triggers at 25km threshold', () {
      final target = LatLng(48.8584, 2.2945);
      final closeGuess = LatLng(48.8800, 2.3100); // ~24km away
      final distance = DistanceCalculator.calculate(closeGuess, target);

      expect(distance, lessThan(25));
    });

    test('same location returns 0 distance', () {
      final point = LatLng(0, 0);
      final distance = DistanceCalculator.calculate(point, point);

      expect(distance, equals(0));
    });
  });

  group('FeedbackThresholds', () {
    test('assigns correct emoji for distance ranges', () {
      expect(_getEmoji(20), equals('🔥'));
      expect(_getEmoji(100), equals('♨️'));
      expect(_getEmoji(300), equals('🌡️'));
      expect(_getEmoji(700), equals('🧊'));
      expect(_getEmoji(2000), equals('❄️'));
    });
  });
}
```

```dart
// test/challenge_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotgeo/services/challenge_service.dart';

void main() {
  test('returns different challenges for different days', () {
    // Mock different dates
    final challenge1 = ChallengeService.getChallengeForDate(
      DateTime(2025, 1, 1),
    );
    final challenge2 = ChallengeService.getChallengeForDate(
      DateTime(2025, 1, 2),
    );

    expect(challenge1.target, isNot(equals(challenge2.target)));
  });

  test('same date returns same challenge', () {
    final challenge1 = ChallengeService.getChallengeForDate(
      DateTime(2025, 6, 15),
    );
    final challenge2 = ChallengeService.getChallengeForDate(
      DateTime(2025, 6, 15),
    );

    expect(challenge1.target, equals(challenge2.target));
  });
}
```

**Run tests:**
```bash
flutter test
flutter test --coverage  # Generate coverage report
```

---

## 9. Timeline & Complexity

### MVP Timeline (13 days, ~2 hours/day)

| Phase | Tasks | Complexity | Days | Hours |
|-------|-------|------------|------|-------|
| **1. Setup** | Flutter project, dependencies, theme files | Low | 0.5 | 1-2 |
| **2. Map** | flutter_map integration, tap handling, markers | Medium | 2 | 4 |
| **3. Core Game** | State management, 6 attempts, win/lose logic | Medium | 2 | 4 |
| **4. Distance** | Haversine formula, feedback thresholds | Low | 1 | 2 |
| **5. Daily System** | Hardcoded challenges, SharedPreferences | Low | 1 | 2 |
| **6. Hints** | Hot/cold + directional (after attempt 3) | Medium | 1.5 | 3 |
| **7. Share** | Emoji grid generation, share dialog | Low | 0.5 | 1 |
| **8. Aesthetic** | Indiana Jones polish, animations, assets | High | 2.5 | 5 |
| **9. Testing** | Device testing, bug fixes, edge cases | Medium | 2 | 4 |
| **TOTAL** | | | **13 days** | **26 hours** |

### Post-MVP Enhancements

| Feature | Complexity | Time | Priority |
|---------|------------|------|----------|
| **Stats Screen** | Wins, streak, distribution graph | Low | 2 hours | High |
| **Tutorial/Onboarding** | First-time user walkthrough | Medium | 3 hours | High |
| **Difficulty Modes** | Easy/Medium/Hard regions | Low | 1 hour | Medium |
| **Sound Effects** | Vintage map sounds, feedback audio | Low | 2 hours | Medium |
| **Advanced Animations** | Page curls, particle effects | High | 4 hours | Low |
| **Backend API** | Firebase for dynamic challenges | Medium | 4 hours | High |
| **Leaderboards** | Global/friend stats | High | 6 hours | Low |
| **Achievements** | Unlock badges, milestones | Medium | 3 hours | Medium |
| **iOS Build** | iOS-specific testing, App Store prep | Medium | 4 hours | High |

---

## 10. First Day Setup

### Hour 1: Project Initialization

```bash
# Navigate to project directory
cd /Users/10381054/code/personal/hotgeo

# Create Flutter project
flutter create --org com.hotgeo --platforms android,ios hotgeo

# Navigate into project
cd hotgeo

# Test basic run
flutter run
```

### Hour 2: Dependencies & Structure

**Step 1: Update pubspec.yaml**

Add all dependencies from Section 1.

```bash
# Install dependencies
flutter pub get
```

**Step 2: Create directory structure**

```bash
# Create folders
mkdir -p lib/models
mkdir -p lib/services
mkdir -p lib/screens
mkdir -p lib/widgets
mkdir -p lib/theme
mkdir -p lib/utils
mkdir -p lib/data
mkdir -p assets/images
mkdir -p assets/fonts
mkdir -p test
```

**Step 3: Create theme foundation**

Create these files:

1. `lib/theme/app_colors.dart` - Copy color palette from Section 7
2. `lib/theme/app_text_styles.dart` - Copy typography from Section 7

**Step 4: Update main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/game_screen.dart';
import 'models/game_state.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameState(),
      child: HotGeoApp(),
    ),
  );
}

class HotGeoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HotGeo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.leatherBrown,
        scaffoldBackgroundColor: AppColors.parchment,
        colorScheme: ColorScheme.light(
          primary: AppColors.leatherBrown,
          secondary: AppColors.weatheredGold,
        ),
      ),
      home: GameScreen(),
    );
  }
}
```

**Step 5: Create basic GameScreen**

```dart
// lib/screens/game_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class GameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Today's Expedition",
          style: AppTextStyles.title.copyWith(
            fontSize: 24,
            color: AppColors.parchment,
          ),
        ),
        backgroundColor: AppColors.leatherBrown,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "🗺️",
              style: TextStyle(fontSize: 64),
            ),
            SizedBox(height: 16),
            Text(
              "The map awaits, explorer!",
              style: AppTextStyles.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 6: Test on Android**

```bash
# Connect Android phone via USB
# Enable USB debugging in Developer Options

# Run app
flutter run

# You should see:
# - Parchment background color
# - Leather brown app bar
# - Vintage-style text
# - Map emoji placeholder
```

**End of Day 1 Deliverable:**
- ✅ Flutter project created
- ✅ Dependencies installed
- ✅ Theme foundation working
- ✅ App runs on Android
- ✅ Indiana Jones aesthetic visible

---

## 11. Technical Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Map performance on low-end Android** | High | Medium | - Use lightweight OSM tiles<br>- Limit max zoom to 10<br>- Cache tiles aggressively<br>- Test on old device |
| **Daily challenge timezone issues** | High | Medium | - Use UTC for all date calculations<br>- Store as ISO8601 strings<br>- Test with device date changes |
| **Tap accuracy on small screens** | Medium | High | - Minimum tap radius (50px)<br>- Visual ripple on tap<br>- Debounce rapid taps |
| **Internet dependency for map tiles** | Low | High | - flutter_map caches automatically<br>- Show offline message if no cache<br>- Pre-cache popular regions |
| **Storage space for cached tiles** | Low | Low | - Set max cache size (100MB)<br>- Clear old tiles after 30 days<br>- Monitor storage usage |
| **Battery drain from map rendering** | Medium | Low | - Disable animations in background<br>- Limit re-renders<br>- Use release build for testing |
| **Inaccurate distance calculations** | High | Low | - Test Haversine formula extensively<br>- Compare with Google Maps distances<br>- Unit test edge cases |
| **Users changing device date** | Low | Medium | - Accept this as acceptable risk<br>- Could validate with server time (post-MVP) |
| **App size too large** | Low | Low | - Compress assets<br>- Use vector graphics where possible<br>- Typical Flutter app: 15-25MB |

---

## 12. Success Metrics

### MVP Must-Haves (Launch Criteria)

**Functionality:**
- [ ] Game is playable end-to-end on Android
- [ ] Daily challenge system works (new challenge each day)
- [ ] Hot/cold feedback is accurate and helpful
- [ ] Directional hints appear correctly after attempt 3
- [ ] Win/lose conditions trigger properly
- [ ] Share results generates proper emoji grid
- [ ] Stats persist across app restarts

**User Experience:**
- [ ] Indiana Jones aesthetic is evident (colors, fonts, imagery)
- [ ] No crashes or game-breaking bugs
- [ ] Smooth map interaction (zoom/pan/tap at 60fps)
- [ ] Feedback is immediate (<200ms response to tap)
- [ ] App launches in <3 seconds

**Testing:**
- [ ] Tested on at least 2 Android devices (different screen sizes)
- [ ] Edge cases handled (no internet, date changes, app interruptions)
- [ ] All core user flows tested (play game → win/lose → share)

### Post-MVP Nice-to-Haves

**Polish:**
- [ ] Smooth animations (page transitions, marker placement)
- [ ] Sound effects (optional, user-togglable)
- [ ] Tutorial for first-time users
- [ ] Stats screen with graphs

**Features:**
- [ ] Difficulty modes (easy/medium/hard)
- [ ] Achievement badges
- [ ] Streak tracking with rewards
- [ ] Backend API for dynamic challenges

### Key Performance Indicators (Post-Launch)

If pursuing viral growth:

**Day 1-7 Metrics:**
- Daily active users (DAU)
- Share rate (% of games that get shared)
- Retention (% who return next day)
- Completion rate (% who finish game vs abandon)

**Week 2-4 Metrics:**
- Week-over-week growth
- Average streak length
- Social media mentions/hashtags
- App store rating (target: 4.5+)

**Viral Coefficient Target:** >1.0
- If each user brings 1+ new user, growth is exponential
- Share functionality is critical for this

---

## Quick Reference Commands

### Development

```bash
# Run on connected Android device
flutter run

# Hot reload (during development)
# Press 'r' in terminal

# Hot restart
# Press 'R' in terminal

# Run tests
flutter test

# Check for issues
flutter doctor
flutter analyze

# Clean build
flutter clean
flutter pub get
```

### Building

```bash
# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# APK location:
# build/app/outputs/flutter-apk/app-release.apk

# Install APK on connected device
flutter install
```

### Debugging

```bash
# View logs
flutter logs

# Check device connection
adb devices

# Clear app data on device
adb shell pm clear com.hotgeo.hotgeo
```

---

## Next Steps After Reading This Plan

1. **Review the plan** - Does the timeline work for you? Any features to cut/add?

2. **Set up Flutter** - Run `flutter doctor`, ensure Android toolchain ready

3. **Create project** - Follow "First Day Setup" section

4. **Start building** - Begin with Phase 1 (infrastructure + theme)

5. **Test frequently** - Run on Android after each phase

6. **Iterate** - Don't aim for perfection, get MVP working first

7. **Get feedback** - Show to friends after Phase 3 (basic game working)

8. **Polish** - Add Indiana Jones aesthetic in Phase 8

9. **Launch** - Share with small audience, gather data

10. **Improve** - Add post-MVP features based on feedback

---

## Resources & References

**Flutter Documentation:**
- flutter_map: https://pub.dev/packages/flutter_map
- provider: https://pub.dev/packages/provider
- shared_preferences: https://pub.dev/packages/shared_preferences
- share_plus: https://pub.dev/packages/share_plus

**Map Tile Providers:**
- OpenStreetMap: https://www.openstreetmap.org/
- OpenTopoMap: https://opentopomap.org/
- Stamen Maps: http://maps.stamen.com/

**Testing:**
- Flutter Testing Guide: https://docs.flutter.dev/testing
- Widget Testing: https://docs.flutter.dev/cookbook/testing/widget

**Design Inspiration:**
- Indiana Jones aesthetic references
- Vintage map textures: Unsplash, Pexels
- Compass rose SVGs: Free vector sites

---

---

## 13. Open Source Strategy

### Why Open Source is a MASSIVE Differentiator

**Competitive Advantages:**
1. **Community Trust** - "Made by geography lovers, for geography lovers"
2. **Contributor Growth** - Devs worldwide can add challenges, features, translations
3. **Transparency** - No data harvesting concerns, builds trust
4. **Educational** - Students can learn from real-world Flutter codebase
5. **Free Marketing** - GitHub stars, Hacker News visibility, dev community sharing
6. **Fork-Friendly** - Educators can customize for their classrooms

**Viral Multiplier:**
- Open source projects get shared in dev communities (Reddit, HN, Twitter)
- Contributors become advocates
- "Built in public" narrative is compelling
- Press loves "passion project goes viral" stories

### License Choice: MIT License

**Why MIT over GPL/Apache:**
- ✅ Most permissive (maximum adoption)
- ✅ Commercial-friendly (educators/companies can use)
- ✅ Simple, well-understood
- ✅ Allows forks/derivatives
- ❌ No patent protection (acceptable for this project)

**License Text (README.md):**
```markdown
## License

MIT License - Copyright (c) 2025 HotGeo Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy...
```

### Repository Structure

```
hotgeo/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── challenge_submission.md
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/
│       ├── flutter_ci.yml          # Auto-test on PR
│       ├── build_web.yml           # Deploy to GitHub Pages
│       └── release.yml             # Auto-release APK/IPA
├── docs/
│   ├── CONTRIBUTING.md             # How to contribute
│   ├── CODE_OF_CONDUCT.md          # Community guidelines
│   ├── ARCHITECTURE.md             # Technical overview
│   └── ADDING_CHALLENGES.md        # Challenge creation guide
├── lib/                            # Flutter code
├── web/                            # Web-specific files
├── android/                        # Android platform files
├── ios/                            # iOS platform files
├── test/                           # Unit/widget tests
├── README.md                       # Project intro, setup
├── LICENSE                         # MIT License
└── CHANGELOG.md                    # Version history
```

### README.md Structure (Critical for GitHub Discovery)

```markdown
# 🗺️ HotGeo - Daily Geography Challenge Game

> A beautiful daily geography guessing game with Indiana Jones vibes.
> Open source, cross-platform (Android, iOS, Web), and built with Flutter.

[Screenshot of game with vintage map aesthetic]

## Play Now
- 🌐 **Web:** [hotgeo.app](https://hotgeo.app)
- 🤖 **Android:** [Google Play](https://play.google.com/...)
- 🍎 **iOS:** [App Store](https://apps.apple.com/...)

## ✨ Features
- 🌍 Daily geography challenges
- 🔥 Hot/cold feedback system
- 🧭 Progressive directional hints
- 📤 Share results with friends
- 📊 Track your streak
- 🎨 Beautiful Indiana Jones aesthetic
- 🌐 Play on web, Android, or iOS
- 🔐 Sync across devices (Google/Apple sign-in)

## 🎮 How to Play
1. Each day, discover a new mystery location
2. Tap anywhere on the map to make a guess
3. Get hot/cold feedback based on distance
4. After 3 attempts, receive directional hints
5. Find the location in 6 attempts or less!

## 🛠️ Built With
- [Flutter](https://flutter.dev) - Cross-platform framework
- [flutter_map](https://pub.dev/packages/flutter_map) - Free OSM maps
- [Firebase](https://firebase.google.com) - Backend & sync
- [OpenStreetMap](https://www.openstreetmap.org) - Map tiles

## 🚀 Getting Started
### Prerequisites
- Flutter 3.24+
- Dart 3.5+
- Android Studio / Xcode (for mobile)

### Quick Start
\`\`\`bash
# Clone repository
git clone https://github.com/yourusername/hotgeo.git
cd hotgeo

# Install dependencies
flutter pub get

# Run on Android/iOS
flutter run

# Run on Web
flutter run -d chrome
\`\`\`

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for detailed setup.

## 🤝 Contributing
We love contributions! Here's how you can help:

- 🐛 **Report bugs:** [Open an issue](https://github.com/.../issues)
- 💡 **Suggest features:** [Feature request](https://github.com/.../issues)
- 🌍 **Add challenges:** See [ADDING_CHALLENGES.md](docs/ADDING_CHALLENGES.md)
- 🌐 **Translate:** Add your language to `lib/l10n/`
- 💻 **Code:** Pick up a [good first issue](https://github.com/.../labels/good%20first%20issue)

## 📜 License
MIT License - see [LICENSE](LICENSE) for details

## 🙏 Acknowledgments
- OpenStreetMap contributors
- Flutter community
- All our amazing contributors!

## ⭐ Star History
[Embed star history chart]
```

### CONTRIBUTING.md Template

```markdown
# Contributing to HotGeo

Thanks for your interest! Here's how to get involved:

## Code Contributions

1. **Fork & Clone**
   \`\`\`bash
   git clone https://github.com/YOUR_USERNAME/hotgeo.git
   cd hotgeo
   git checkout -b feature/my-awesome-feature
   \`\`\`

2. **Make Changes**
   - Follow Flutter style guide
   - Add tests for new features
   - Update documentation

3. **Test Locally**
   \`\`\`bash
   flutter test
   flutter analyze
   flutter run
   \`\`\`

4. **Submit PR**
   - Clear description of changes
   - Reference any related issues
   - Screenshots for UI changes

## Adding Daily Challenges

See [ADDING_CHALLENGES.md](ADDING_CHALLENGES.md) for detailed guide.

Quick steps:
1. Edit `lib/data/challenges_2025.dart`
2. Add entry with coordinates, hint, difficulty
3. Test that challenge appears correctly
4. Submit PR

## Translations

1. Copy `lib/l10n/app_en.arb` to `app_XX.arb` (XX = language code)
2. Translate all strings
3. Test with `flutter run --locale=XX`
4. Submit PR

## Questions?
Open a [discussion](https://github.com/.../discussions) or join our [Discord](...)
```

### Community Building Strategy

**Phase 1: Launch (Week 1)**
- Post to r/FlutterDev, r/geography, r/opensource
- Submit to Hacker News
- Tweet with #FlutterDev, #OpenSource, #MadeWithFlutter
- Cross-post to dev.to, Medium

**Phase 2: Early Contributors (Week 2-4)**
- Label issues "good first issue", "help wanted"
- Respond to PRs within 24 hours
- Feature contributors in README
- Create detailed ARCHITECTURE.md to lower barrier

**Phase 3: Sustained Growth (Month 2+)**
- Monthly challenge design contests
- Highlight community contributions on social
- Create video tutorials
- Apply for GitHub Sponsors

### Monetization (Optional, Post-Launch)

**How to monetize without compromising open source:**

1. **Donations (Ethical):**
   - GitHub Sponsors
   - Ko-fi / Buy Me a Coffee
   - "Support development" in app (optional)

2. **Premium Features (Optional):**
   - Keep core game 100% free
   - Optional premium: Custom challenges, themes, ad-free
   - Code stays open source (premium features in separate package)

3. **Sponsorships (Later):**
   - Geography education companies
   - Travel brands ("Powered by [Brand]")
   - Ethical, non-intrusive placement

**IMPORTANT:** Open source doesn't mean unprofitable. Many successful OSS projects are sustainable.

---

## 14. Cross-Platform Sync & Accounts

### Architecture Overview

**Multi-Platform Challenge:**
- Android uses Google Play Games
- iOS uses Game Center
- Web uses Firebase Auth
- All three must sync to same backend

**Solution: Firebase as Universal Backend**

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Android   │     │     iOS     │     │     Web     │
│  (Google)   │     │(Game Center)│     │  (Firebase) │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                    ┌──────▼──────┐
                    │  Firebase   │
                    │  Firestore  │
                    │   + Auth    │
                    └─────────────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
       ┌────▼────┐    ┌────▼────┐   ┌────▼────┐
       │  Stats  │    │ Streaks │   │Challenges│
       └─────────┘    └─────────┘   └─────────┘
```

### Updated Dependencies

```yaml
dependencies:
  # Existing dependencies...

  # Firebase (free tier: 50k reads/day, 20k writes/day)
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4

  # Google Sign-In (Android/Web)
  google_sign_in: ^6.2.1

  # Apple Sign-In (iOS/Web)
  sign_in_with_apple: ^6.1.3

  # Platform detection
  universal_io: ^2.2.2
```

### Firebase Setup (One-Time)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Create Firebase project (web console or CLI)
firebase projects:create hotgeo-app

# Initialize Flutter app with Firebase
flutterfire configure
```

**FlutterFire configuration creates:**
- `firebase_options.dart` - Auto-generated config
- Registers Android, iOS, Web apps

**Cost:** $0/month on Spark (free) plan for MVP
- 50k reads/day, 20k writes/day
- 1 GB storage
- Sufficient for 1000s of users

### Authentication Service Implementation

```dart
// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with platform-appropriate method
  Future<UserCredential?> signIn() async {
    // Web or Android: Google Sign-In
    if (kIsWeb || Platform.isAndroid) {
      return await _signInWithGoogle();
    }

    // iOS: Apple Sign-In (required by App Store)
    if (Platform.isIOS) {
      return await _signInWithApple();
    }

    return null;
  }

  // Google Sign-In (Android, Web)
  Future<UserCredential?> _signInWithGoogle() async {
    try {
      // Trigger Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null; // User cancelled

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google sign-in error: $e');
      return null;
    }
  }

  // Apple Sign-In (iOS, Web)
  Future<UserCredential?> _signInWithApple() async {
    try {
      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create Firebase credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase
      return await _auth.signInWithCredential(oauthCredential);
    } catch (e) {
      print('Apple sign-in error: $e');
      return null;
    }
  }

  // Anonymous sign-in (fallback, no sync)
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Link anonymous account to real account (upgrade path)
  Future<UserCredential?> upgradeAnonymousAccount() async {
    if (!currentUser!.isAnonymous) return null;

    final credential = await signIn();
    if (credential == null) return null;

    // Link anonymous account with new credential
    return await currentUser!.linkWithCredential(
      credential.credential!,
    );
  }
}
```

### Cloud Firestore Data Model

```
users/{userId}
  ├── email: "user@example.com"
  ├── displayName: "Explorer"
  ├── createdAt: Timestamp
  ├── lastPlayed: "2025-11-22"
  └── stats/
      ├── totalWins: 42
      ├── totalLosses: 8
      ├── currentStreak: 7
      ├── bestStreak: 15
      ├── gamesPlayed: 50
      └── averageAttempts: 3.8

users/{userId}/games/{gameDate}
  ├── date: "2025-11-22"
  ├── challengeId: "eiffel-tower"
  ├── won: true
  ├── attempts: 4
  ├── guesses: [
  │     {lat: 48.0, lng: 2.0, distance: 1200},
  │     {lat: 48.5, lng: 2.2, distance: 400},
  │     ...
  │   ]
  ├── completedAt: Timestamp
  └── shareCount: 2
```

### Sync Service Implementation

```dart
// lib/services/sync_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Save game result to cloud
  Future<void> saveGameResult({
    required DateTime date,
    required bool won,
    required int attempts,
    required List<Map<String, dynamic>> guesses,
  }) async {
    if (_userId == null) return; // Not signed in

    final gameDate = date.toIso8601String().split('T')[0];

    // Save individual game
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('games')
        .doc(gameDate)
        .set({
      'date': gameDate,
      'won': won,
      'attempts': attempts,
      'guesses': guesses,
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Update stats
    await _updateStats(won, attempts);
  }

  // Update user statistics
  Future<void> _updateStats(bool won, int attempts) async {
    final userDoc = _firestore.collection('users').doc(_userId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);

      final data = snapshot.data() ?? {};
      final int totalWins = (data['totalWins'] ?? 0) + (won ? 1 : 0);
      final int totalLosses = (data['totalLosses'] ?? 0) + (!won ? 1 : 0);
      final int currentStreak = won
          ? (data['currentStreak'] ?? 0) + 1
          : 0;
      final int bestStreak = currentStreak > (data['bestStreak'] ?? 0)
          ? currentStreak
          : (data['bestStreak'] ?? 0);

      transaction.set(userDoc, {
        'totalWins': totalWins,
        'totalLosses': totalLosses,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'gamesPlayed': totalWins + totalLosses,
        'lastPlayed': DateTime.now().toIso8601String().split('T')[0],
      }, SetOptions(merge: true));
    });
  }

  // Fetch user stats from cloud
  Future<Map<String, dynamic>?> getUserStats() async {
    if (_userId == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .get();

    return doc.data();
  }

  // Check if user has played today (cloud check)
  Future<bool> hasPlayedToday() async {
    if (_userId == null) return false;

    final today = DateTime.now().toIso8601String().split('T')[0];

    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('games')
        .doc(today)
        .get();

    return doc.exists;
  }

  // Sync local stats to cloud (for migration)
  Future<void> syncLocalToCloud(Map<String, dynamic> localStats) async {
    if (_userId == null) return;

    await _firestore
        .collection('users')
        .doc(_userId)
        .set(localStats, SetOptions(merge: true));
  }
}
```

### UI: Sign-In Screen

```dart
// lib/screens/sign_in_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SignInScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Text(
              "🗺️",
              style: TextStyle(fontSize: 80),
            ),
            SizedBox(height: 16),

            // Title
            Text(
              "HotGeo",
              style: AppTextStyles.title,
            ),
            SizedBox(height: 8),
            Text(
              "Daily Geography Challenge",
              style: AppTextStyles.subtitle,
            ),

            SizedBox(height: 48),

            // Sign-in button (platform-adaptive)
            ElevatedButton.icon(
              onPressed: () async {
                final result = await _authService.signIn();
                if (result != null) {
                  // Navigate to game
                  Navigator.pushReplacementNamed(context, '/game');
                }
              },
              icon: Icon(Icons.login),
              label: Text(_getSignInButtonText()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.leatherBrown,
                foregroundColor: AppColors.parchment,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),

            SizedBox(height: 16),

            // Play without account
            TextButton(
              onPressed: () async {
                await _authService.signInAnonymously();
                Navigator.pushReplacementNamed(context, '/game');
              },
              child: Text(
                "Play without account (no sync)",
                style: AppTextStyles.bodySecondary,
              ),
            ),

            SizedBox(height: 32),

            // Privacy info
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                "Sign in to sync your streak across devices.\n"
                "We only store your game stats.",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSignInButtonText() {
    if (kIsWeb || Platform.isAndroid) {
      return "Sign in with Google";
    } else if (Platform.isIOS) {
      return "Sign in with Apple";
    }
    return "Sign In";
  }
}
```

### Testing Cross-Platform Sync

**Test Scenario:**
1. Play game on Android (signed in with Google)
2. Open web version (sign in with same Google account)
3. Verify streak/stats match
4. Play on iOS (sign in with Apple, but same email)
5. Verify all stats synced

**Firestore Rules (Security):**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /games/{gameDate} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Challenges are public (read-only)
    match /challenges/{challengeId} {
      allow read: if true;
      allow write: if false; // Only admin can write
    }
  }
}
```

---

## 15. Web Deployment

### Why Web Version is Critical

**Advantages:**
1. **Zero friction** - No app store approval, instant play
2. **SEO** - Google can index, drive organic traffic
3. **Sharing** - Direct links (hotgeo.app/challenge/327)
4. **Testing** - Fastest way to get feedback
5. **Viral spread** - Easier to share than "download app"

### Flutter Web Setup

```bash
# Enable web support (if not already)
flutter create --platforms=web .

# Run locally
flutter run -d chrome

# Build for production
flutter build web --release

# Output: build/web/
```

### Hosting Options (All Free)

**Option 1: Firebase Hosting (RECOMMENDED)**
- Free tier: 10 GB storage, 360 MB/day transfer
- Custom domain support
- Auto HTTPS
- CDN included
- Integrated with Firebase (already using for backend)

**Option 2: GitHub Pages**
- Free tier: Unlimited for public repos
- Custom domain support
- Auto deploy from GitHub Actions
- No backend (suitable for static hosting)

**Option 3: Vercel/Netlify**
- Free tier: 100 GB bandwidth/month
- Auto deploy from Git
- Custom domains
- Serverless functions (if needed)

### Firebase Hosting Deployment

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize hosting
firebase init hosting

# Select options:
# - Use existing Firebase project (hotgeo-app)
# - Public directory: build/web
# - Configure as single-page app: Yes
# - Auto builds with GitHub: Yes (optional)

# Deploy
firebase deploy --only hosting

# Your app is now live at:
# https://hotgeo-app.web.app
# https://hotgeo-app.firebaseapp.com
```

### Custom Domain Setup

```bash
# Add custom domain in Firebase Console
# Settings > Hosting > Add custom domain

# Follow DNS setup instructions
# Example for hotgeo.app:
# A record: @ → 151.101.1.195, 151.101.65.195
# CNAME: www → hotgeo-app.web.app

# Firebase auto-provisions SSL certificate
```

### Automated Deployment with GitHub Actions

```yaml
# .github/workflows/deploy_web.yml
name: Deploy to Firebase Hosting

on:
  push:
    branches:
      - main

jobs:
  build_and_deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Build web
        run: flutter build web --release

      - name: Deploy to Firebase Hosting
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: hotgeo-app
```

### Web-Specific Optimizations

**1. index.html Metadata (SEO)**

```html
<!-- web/index.html -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <!-- SEO -->
  <title>HotGeo - Daily Geography Challenge Game</title>
  <meta name="description" content="Play the daily geography challenge! Find mystery locations on a vintage map with hot/cold hints. Open source and free.">
  <meta name="keywords" content="geography game, daily challenge, wordle, hot cold game, map game">

  <!-- Open Graph (Social Sharing) -->
  <meta property="og:title" content="HotGeo - Daily Geography Challenge">
  <meta property="og:description" content="I found today's mystery location in 4 tries! Can you beat me?">
  <meta property="og:image" content="https://hotgeo.app/og-image.png">
  <meta property="og:url" content="https://hotgeo.app">
  <meta property="og:type" content="website">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="HotGeo - Daily Geography Challenge">
  <meta name="twitter:description" content="Find the mystery location on a vintage map!">
  <meta name="twitter:image" content="https://hotgeo.app/twitter-card.png">

  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png"/>

  <!-- App manifest -->
  <link rel="manifest" href="manifest.json">

  <!-- Theme color -->
  <meta name="theme-color" content="#F4E8D0">

  <!-- iOS meta tags -->
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="HotGeo">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
</head>
<body>
  <script src="main.dart.js" type="application/javascript"></script>
</body>
</html>
```

**2. Progressive Web App (PWA) Manifest**

```json
// web/manifest.json
{
  "name": "HotGeo - Daily Geography Challenge",
  "short_name": "HotGeo",
  "description": "Daily geography guessing game with vintage maps",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#F4E8D0",
  "theme_color": "#3D2817",
  "orientation": "portrait-primary",
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ]
}
```

**3. Service Worker (Offline Support)**

Flutter web auto-generates service worker. To customize:

```javascript
// web/flutter_service_worker.js
// Auto-generated by Flutter build
// Caches assets for offline play
```

### Web Performance Optimization

**CanvasKit vs HTML Renderer:**

```bash
# Default: Auto-detect
flutter build web --release

# Force HTML renderer (smaller, faster load)
flutter build web --web-renderer html --release

# Force CanvasKit (better graphics, larger)
flutter build web --web-renderer canvaskit --release
```

**Recommendation:** Use `html` renderer for MVP (smaller bundle, faster load)

### Analytics Integration (Optional)

```yaml
dependencies:
  firebase_analytics: ^11.3.3
```

```dart
// lib/main.dart
import 'package:firebase_analytics/firebase_analytics.dart';

void main() {
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  runApp(HotGeoApp(analytics: analytics));
}

// Track events
await analytics.logEvent(
  name: 'game_completed',
  parameters: {
    'won': true,
    'attempts': 4,
    'challenge_id': 'eiffel-tower',
  },
);
```

### Web Testing Checklist

- [ ] Responsive design (test 320px → 4K)
- [ ] Touch events work on mobile browsers
- [ ] Map zoom works (pinch-to-zoom)
- [ ] Share functionality (uses Web Share API)
- [ ] Sign-in works (Google OAuth)
- [ ] PWA installable (shows "Add to Home Screen")
- [ ] Works offline after first load
- [ ] Fast load time (<3 seconds on 3G)
- [ ] SEO metadata correct (view source)
- [ ] Social cards preview correctly (Twitter, Facebook)

### Cross-Platform Feature Parity

| Feature | Android | iOS | Web |
|---------|---------|-----|-----|
| Core game | ✅ | ✅ | ✅ |
| Sign-in | Google | Apple | Google |
| Share | Native | Native | Web Share API |
| Notifications | FCM | APNs | Web Push (optional) |
| Install | Play Store | App Store | PWA (Add to Home) |
| Offline | ✅ | ✅ | ✅ (after first load) |

---

## Updated Timeline with Cross-Platform

### Extended Timeline (18 days total)

| Phase | Tasks | Days | Hours |
|-------|-------|------|-------|
| **Phases 1-9** | Core MVP (Android) | 13 | 26 |
| **Phase 10** | Firebase setup & auth | 1 | 2 |
| **Phase 11** | Cloud sync implementation | 1 | 2 |
| **Phase 12** | iOS build & Apple sign-in | 1 | 2 |
| **Phase 13** | Web build & deployment | 1 | 2 |
| **Phase 14** | Open source prep (README, docs) | 1 | 2 |
| **TOTAL** | | **18 days** | **36 hours** |

**Launch Checklist:**
- [ ] MVP works on Android
- [ ] Works on iOS (TestFlight)
- [ ] Works on Web (Firebase Hosting)
- [ ] GitHub repo public with README
- [ ] Firebase sync works across platforms
- [ ] Tested sign-in on all platforms
- [ ] Social sharing works
- [ ] Domain configured (hotgeo.app)

---

**Document Version:** 2.0
**Last Updated:** 2025-11-22
**Author:** HotGeo Development Team

---

**Ready to build an open-source viral hit? Let's go! 🗺️🔥**
