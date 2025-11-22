# 🚀 HotGeo Web Prototype - 2-Hour Sprint Plan

**Goal:** Working web game deployed to Firebase Hosting in 120 minutes
**Date:** End of 2025
**Tech Stack:** Flutter 3.24+ (CanvasKit), flutter_map 7.0, Firebase Hosting

---

## **Technology Stack Decision (2025 Best Practices)**

### 🎯 **Final Tech Choices**
- **Web Renderer:** CanvasKit (default in Flutter 3.24+, HTML deprecated)
- **Layout:** MediaQuery.sizeOf for breakpoints + Flexible/Expanded for responsive
- **State:** Simple setState (fastest for prototype, no Provider setup)
- **Map:** flutter_map with default OSM tiles (browser caches automatically)
- **Deployment:** Firebase Hosting (5-minute deploy)

### 📱 **Breakpoints**
```dart
// Material Design 3 standard breakpoints
static const double mobileBreakpoint = 600;
static const double tabletBreakpoint = 840;
static const double desktopBreakpoint = 1200;
```

---

## **⏰ HOUR 1: Core Game Engine (0-60 minutes)**

### **🕐 Minutes 0-15: Project Setup & Dependencies**

```bash
# Terminal commands - COPY EXACTLY
cd /Users/10381054/code/personal/hotgeo
flutter create --platforms=web hotgeo_web
cd hotgeo_web
```

**pubspec.yaml** (minimal dependencies):
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_map: ^7.0.0  # Latest for 2025
  latlong2: ^0.9.1
  http: ^1.2.0
```

```bash
flutter pub get
flutter run -d chrome --web-port=3000  # Keep running for hot reload
```

### **🕐 Minutes 15-30: Map & Core Game State**

**lib/main.dart** - Complete replacement:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';

void main() => runApp(const HotGeoApp());

class HotGeoApp extends StatelessWidget {
  const HotGeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HotGeo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B4513), // Leather brown
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // HARDCODED for prototype - Paris, France
  final LatLng _targetLocation = const LatLng(48.8566, 2.3522);
  final List<LatLng> _guesses = [];
  final MapController _mapController = MapController();
  int _attemptsLeft = 6;
  double? _lastDistance;
  String _feedback = "Tap the map to guess!";

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF4E4C1), // Parchment
      body: SafeArea(
        child: screenWidth < 600
          ? _buildMobileLayout()
          : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildMap()),
        _buildFeedbackPanel(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildMap()),
            ],
          ),
        ),
        Container(
          width: 350,
          color: const Color(0xFFE8D4B0),
          child: _buildFeedbackPanel(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF8B4513).withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'HotGeo',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
          Text(
            'Attempts: $_attemptsLeft/6',
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(40, 0), // World view
        initialZoom: 2,
        onTap: _handleMapTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        MarkerLayer(
          markers: _guesses.asMap().entries.map((entry) {
            return Marker(
              point: entry.value,
              width: 40,
              height: 40,
              child: Icon(
                Icons.location_on,
                color: _getMarkerColor(entry.key),
                size: 40,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _handleMapTap(TapPosition tapPos, LatLng point) {
    if (_attemptsLeft <= 0) return;

    setState(() {
      _guesses.add(point);
      _attemptsLeft--;
      _lastDistance = _calculateDistance(point, _targetLocation);
      _feedback = _generateFeedback(_lastDistance!);

      if (_lastDistance! < 50) { // Within 50km = WIN!
        _feedback = "🎉 YOU FOUND IT! Distance: ${_lastDistance!.toStringAsFixed(0)}km";
      } else if (_attemptsLeft == 0) {
        _feedback = "Game Over! It was in Paris, France";
      }
    });
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, p1, p2);
  }

  String _generateFeedback(double distance) {
    if (distance < 100) return "🔥 BURNING HOT!";
    if (distance < 500) return "🌡️ Very warm!";
    if (distance < 1000) return "♨️ Getting warmer...";
    if (distance < 2000) return "❄️ Cold...";
    return "🧊 Freezing cold!";
  }

  Color _getMarkerColor(int index) {
    if (index >= _guesses.length) return Colors.grey;
    final distance = _calculateDistance(_guesses[index], _targetLocation);
    if (distance < 100) return Colors.red;
    if (distance < 500) return Colors.orange;
    if (distance < 1000) return Colors.yellow;
    return Colors.blue;
  }

  Widget _buildFeedbackPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _feedback,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (_lastDistance != null) ...[
            const SizedBox(height: 10),
            Text(
              'Distance: ${_lastDistance!.toStringAsFixed(0)} km',
              style: const TextStyle(fontSize: 18),
            ),
          ],
          const SizedBox(height: 20),
          if (_attemptsLeft == 0 || (_lastDistance != null && _lastDistance! < 50))
            ElevatedButton(
              onPressed: _resetGame,
              child: const Text('Play Again'),
            ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _guesses.clear();
      _attemptsLeft = 6;
      _lastDistance = null;
      _feedback = "Tap the map to guess!";
    });
  }
}
```

### **🕐 Minutes 30-45: Test Core Gameplay**

1. Save the file (hot reload automatically updates)
2. Click on map to place guesses
3. Verify hot/cold feedback works
4. Test on different screen sizes (Chrome DevTools)
5. Fix any immediate bugs

### **🕐 Minutes 45-60: Polish & Visual Enhancements**

Quick CSS-like improvements (add to `_buildMap`):
```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(color: const Color(0xFF8B4513), width: 3),
    boxShadow: [
      BoxShadow(
        color: Colors.brown.withOpacity(0.3),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: FlutterMap(...),
  ),
)
```

---

## **⏰ HOUR 2: Features & Deployment (60-120 minutes)**

### **🕑 Minutes 60-75: Add Share & Score System**

Add to `_GameScreenState`:
```dart
String _generateShareText() {
  final attempts = 6 - _attemptsLeft;
  final squares = _guesses.map((g) {
    final d = _calculateDistance(g, _targetLocation);
    if (d < 100) return '🟥';
    if (d < 500) return '🟧';
    if (d < 1000) return '🟨';
    return '🟦';
  }).join();

  return 'HotGeo ${DateTime.now().day}/${DateTime.now().month}\n'
         'Attempts: $attempts/6\n'
         '$squares\n'
         'Play at: hotgeo.web.app';
}

// Add share button in feedback panel
IconButton(
  icon: const Icon(Icons.share),
  onPressed: () {
    // For web, copy to clipboard
    final text = _generateShareText();
    // Simple web share (no dependencies needed)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Score copied!\n$text')),
    );
  },
)
```

### **🕑 Minutes 75-90: Random Daily Location**

Replace hardcoded location:
```dart
// Add at top of _GameScreenState
LatLng _getDailyLocation() {
  // Use date as seed for consistent daily challenge
  final today = DateTime.now();
  final seed = today.year * 10000 + today.month * 100 + today.day;
  final random = Random(seed);

  // 50 interesting world cities (hardcoded for prototype)
  final cities = [
    const LatLng(48.8566, 2.3522),   // Paris
    const LatLng(40.7128, -74.0060), // New York
    const LatLng(35.6762, 139.6503), // Tokyo
    const LatLng(-33.8688, 151.2093), // Sydney
    const LatLng(51.5074, -0.1278),  // London
    const LatLng(55.7558, 37.6173),  // Moscow
    const LatLng(28.6139, 77.2090),  // Delhi
    const LatLng(-23.5505, -46.6333), // São Paulo
    const LatLng(19.4326, -99.1332), // Mexico City
    const LatLng(31.2304, 121.4737), // Shanghai
    const LatLng(34.0522, -118.2437), // Los Angeles
    const LatLng(41.9028, 12.4964),  // Rome
    const LatLng(52.5200, 13.4050),  // Berlin
    const LatLng(37.5665, 126.9780), // Seoul
    const LatLng(-34.6037, -58.3816), // Buenos Aires
    const LatLng(39.9042, 116.4074), // Beijing
    const LatLng(25.2048, 55.2708),  // Dubai
    const LatLng(1.3521, 103.8198),  // Singapore
    const LatLng(45.4215, -75.6972), // Ottawa
    const LatLng(-37.8136, 144.9631), // Melbourne
  ];

  return cities[random.nextInt(cities.length)];
}

// Replace in class definition
late final LatLng _targetLocation = _getDailyLocation();
```

### **🕑 Minutes 90-105: Build for Web**

```bash
# Build optimized web version
flutter build web --release --web-renderer canvaskit

# Files will be in build/web/
```

### **🕑 Minutes 105-120: Deploy to Firebase Hosting**

```bash
# Install Firebase CLI (if not installed)
npm install -g firebase-tools

# Initialize Firebase in project
firebase login
firebase init hosting

# When prompted:
# - Select "Create new project"
# - Project ID: hotgeo-2025
# - Public directory: build/web
# - Single-page app: Yes
# - Overwrite index.html: No

# Deploy!
firebase deploy

# Your app is now live at: https://hotgeo-2025.web.app
```

---

## **📋 What to Skip/Defer (Save Time)**

### **SKIP for Prototype:**
- ❌ User accounts/authentication
- ❌ Database for locations
- ❌ Animations/transitions
- ❌ Custom fonts (use defaults)
- ❌ Settings screen
- ❌ Tutorial/onboarding
- ❌ Sound effects
- ❌ Offline support
- ❌ Unit tests

### **HARDCODE for Speed:**
- ✅ Target locations (array of 20 cities)
- ✅ Date-based seeding (no backend needed)
- ✅ Distance thresholds (100, 500, 1000, 2000 km)
- ✅ Color scheme (use Color() directly)

---

## **✅ Minimum Viable Features (Must Work)**

1. **Map displays and accepts taps** ✓
2. **6 guesses tracked visually** ✓
3. **Hot/cold feedback shown** ✓
4. **Distance calculation works** ✓
5. **Win/lose conditions** ✓
6. **Daily location (date-seeded)** ✓
7. **Responsive layout (mobile/desktop)** ✓
8. **Deployed to public URL** ✓

---

## **🚨 Emergency Shortcuts**

If running behind schedule:

### **30-MIN VERSION:**
- Skip responsive layout (mobile only)
- Skip share feature
- Hardcode single location
- Skip Firebase, use GitHub Pages

### **1-HOUR VERSION:**
- Basic map + gameplay only
- Skip all visual polish
- Manual deployment

---

## **📝 Testing Checklist (Final 5 minutes)**

- [ ] Open on phone browser
- [ ] Open on desktop browser
- [ ] Place 6 guesses
- [ ] Win condition (guess near target)
- [ ] Lose condition (6 wrong guesses)
- [ ] Reset game button
- [ ] No console errors
- [ ] Share the URL!

---

## **Key Success Factors**

1. **Use hot reload aggressively** - Don't restart app
2. **Copy code blocks exactly** - Don't modify on first pass
3. **Skip perfectionism** - Working > Perfect
4. **Test on real device early** - Use phone + desktop
5. **Deploy at 90 minutes** - Leave buffer for issues

---

## **2025 Flutter Web Best Practices Applied**

### ✅ **What We're Using:**
- **CanvasKit renderer** (HTML deprecated)
- **MediaQuery.sizeOf** (newer API, better performance)
- **Material 3** (latest design system)
- **useMaterial3: true** (enables MD3 components)
- **flutter_map 7.0** (latest stable for web)

### ✅ **Responsive Design:**
- Mobile-first breakpoint: 600px
- Desktop layout with sidebar
- MediaQuery for screen size detection
- Flexible/Expanded for adaptive layouts

### ✅ **Performance:**
- Minimal dependencies
- No heavy state management
- Browser caching for map tiles
- CanvasKit for smooth rendering

---

**Ready to start? Run the first command and let's build! 🚀**
