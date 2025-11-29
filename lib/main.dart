import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:html' as html show window, Navigator;
// ignore: deprecated_member_use
import 'dart:js_util' as js_util;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HotGeoApp());
}

class HotGeoApp extends StatelessWidget {
  const HotGeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HotGeo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D428A), // Warriors blue
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        fontFamily: 'SF Pro Display', // Clean modern font
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

class LocationChallenge {
  final int id; // Unique ID from 1-365 for daily challenge
  final String name;
  final LatLng coordinates;
  final double initialZoom;
  final double answerZoom; // Zoom level where name is visible
  final double winThresholdKm; // Distance within which you "win"
  final String difficulty; // easy/medium/hard
  final Map<String, dynamic> hints; // country, region, population

  const LocationChallenge({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.initialZoom,
    required this.answerZoom,
    required this.winThresholdKm,
    required this.difficulty,
    required this.hints,
  });

  factory LocationChallenge.fromJson(Map<String, dynamic> json) {
    return LocationChallenge(
      id: json['id'] as int,
      name: json['name'] as String,
      coordinates: LatLng(
        (json['coordinates']['lat'] as num).toDouble(),
        (json['coordinates']['lng'] as num).toDouble(),
      ),
      initialZoom: (json['zoom'] as num).toDouble(),
      answerZoom: (json['answerZoom'] as num).toDouble(),
      winThresholdKm: (json['winThresholdKm'] as num).toDouble(),
      difficulty: json['difficulty'] as String,
      hints: json['hints'] as Map<String, dynamic>,
    );
  }
}

class GameResult {
  final String locationName;
  final String difficulty;
  final bool won;
  final int attempts;
  final DateTime timestamp;

  GameResult({
    required this.locationName,
    required this.difficulty,
    required this.won,
    required this.attempts,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'locationName': locationName,
      'difficulty': difficulty,
      'won': won,
      'attempts': attempts,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      locationName: json['locationName'] as String,
      difficulty: json['difficulty'] as String,
      won: json['won'] as bool,
      attempts: json['attempts'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  String getDifficultyEmoji() {
    if (difficulty == 'easy') return '🟢';
    if (difficulty == 'medium') return '🟡';
    return '🔴';
  }
}

// Model for location metadata (fun facts, food, visual elements)
class LocationMetadata {
  final String name;
  final String country;
  final String funFact;
  final FoodAndDrink? foodAndDrink;
  final VisualElements? visualElements;
  final int locationId;

  LocationMetadata({
    required this.name,
    required this.country,
    required this.funFact,
    this.foodAndDrink,
    this.visualElements,
    required this.locationId,
  });

  factory LocationMetadata.fromJson(Map<String, dynamic> json) {
    return LocationMetadata(
      name: json['name'] as String? ?? '',
      country: json['country'] as String? ?? '',
      funFact: json['fun_fact'] as String? ?? '',
      foodAndDrink: json['food_and_drink'] != null
          ? FoodAndDrink.fromJson(json['food_and_drink'])
          : null,
      visualElements: json['visual_elements'] != null
          ? VisualElements.fromJson(json['visual_elements'])
          : null,
      locationId: json['location_id'] as int? ?? 0,
    );
  }
}

class FoodAndDrink {
  final List<HeroDish> heroDishes;
  final List<SignatureDrink> signatureDrinks;
  final List<String> foodCultureNotes;

  FoodAndDrink({
    required this.heroDishes,
    required this.signatureDrinks,
    required this.foodCultureNotes,
  });

  factory FoodAndDrink.fromJson(Map<String, dynamic> json) {
    return FoodAndDrink(
      heroDishes: (json['hero_dishes'] as List<dynamic>?)
              ?.map((d) => HeroDish.fromJson(d))
              .toList() ??
          [],
      signatureDrinks: (json['signature_drinks'] as List<dynamic>?)
              ?.map((d) => SignatureDrink.fromJson(d))
              .toList() ??
          [],
      foodCultureNotes: (json['food_culture_notes'] as List<dynamic>?)
              ?.map((n) => n.toString())
              .toList() ??
          [],
    );
  }
}

class HeroDish {
  final String name;
  final String description;
  final String? originStory;
  final String? whereToFind;

  HeroDish({
    required this.name,
    required this.description,
    this.originStory,
    this.whereToFind,
  });

  factory HeroDish.fromJson(Map<String, dynamic> json) {
    return HeroDish(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      originStory: json['origin_story'] as String?,
      whereToFind: json['where_to_find'] as String?,
    );
  }
}

class SignatureDrink {
  final String name;
  final String description;
  final String? howLocalsDrinkIt;

  SignatureDrink({
    required this.name,
    required this.description,
    this.howLocalsDrinkIt,
  });

  factory SignatureDrink.fromJson(Map<String, dynamic> json) {
    return SignatureDrink(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      howLocalsDrinkIt: json['how_locals_drink_it'] as String?,
    );
  }
}

class VisualElements {
  final List<String> landmarks;
  final List<String> atmosphere;
  final List<String> colors;
  final List<String> uniqueModern;

  VisualElements({
    required this.landmarks,
    required this.atmosphere,
    required this.colors,
    required this.uniqueModern,
  });

  factory VisualElements.fromJson(Map<String, dynamic> json) {
    return VisualElements(
      landmarks: (json['landmarks'] as List<dynamic>?)
              ?.map((l) => l.toString())
              .toList() ??
          [],
      atmosphere: (json['atmosphere'] as List<dynamic>?)
              ?.map((a) => a.toString())
              .toList() ??
          [],
      colors: (json['colors'] as List<dynamic>?)
              ?.map((c) => c.toString())
              .toList() ??
          [],
      uniqueModern: (json['unique_modern'] as List<dynamic>?)
              ?.map((u) => u.toString())
              .toList() ??
          [],
    );
  }
}

class _GameScreenState extends State<GameScreen> {
  List<LocationChallenge>? _allChallenges; // Loaded from JSON
  LocationChallenge? _challenge; // Current challenge
  final List<LatLng> _guesses = [];
  final MapController _mapController = MapController();
  int _attemptsLeft = 6;
  double? _lastDistance;
  String _feedback = "Tap the map to guess the location!";
  bool _isLoading = true;
  bool _hintUsed = false;
  bool _showRadiusHint = false; // Toggle for circular radius hint

  // Session tracking
  int _winStreak = 0;
  List<GameResult> _recentGames = [];
  int _todayWins = 0;
  int _todayGames = 0;
  bool _guessHistoryExpanded = false;

  // Location progression tracking
  int _currentLocationId = 1; // Current location in progression (1-365)

  // Location metadata for discovery card
  LocationMetadata? _locationMetadata;
  bool _showDiscoveryCard = false;
  int _discoveryCardPage = 0; // 0 = fun fact, 1 = food, 2 = drinks

  @override
  void initState() {
    super.initState();
    _loadChallenges();
    _loadSessionStats();
  }

  Future<void> _loadChallenges() async {
    try {
      // Load JSON from assets
      final String jsonString = await rootBundle.loadString('assets/locations.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Parse locations
      final List<dynamic> locationsJson = jsonData['locations'];
      _allChallenges = locationsJson
          .map((json) => LocationChallenge.fromJson(json))
          .toList();

      // Initialize location progression
      await _initializeLocationProgression();

      setState(() {
        _challenge = _getCurrentChallenge();
        _loadState(); // Load saved progress
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading challenges: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveState() async {
    if (_challenge != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final state = {
          'locationName': _challenge!.name,
          'attemptsLeft': _attemptsLeft,
          'hintUsed': _hintUsed,
          'showRadiusHint': _showRadiusHint,
          'lastDistance': _lastDistance,
          'feedback': _feedback,
          'guesses': _guesses.map((g) => {'lat': g.latitude, 'lng': g.longitude}).toList(),
        };
        await prefs.setString('hotgeo_state', json.encode(state));
      } catch (e) {
        if (kDebugMode) {
          print('Error saving state: $e');
        }
      }
    }
  }

  Future<void> _loadState() async {
    if (_challenge != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedState = prefs.getString('hotgeo_state');
        if (savedState != null) {
          final state = json.decode(savedState) as Map<String, dynamic>;

          // Only load if it's the same location
          if (state['locationName'] == _challenge!.name) {
            setState(() {
              _attemptsLeft = state['attemptsLeft'] as int;
              _hintUsed = state['hintUsed'] as bool;
              _showRadiusHint = state['showRadiusHint'] as bool;
              _lastDistance = state['lastDistance'] as double?;
              _feedback = state['feedback'] as String;
              _guesses.clear();
              for (final g in state['guesses'] as List) {
                _guesses.add(LatLng(g['lat'] as double, g['lng'] as double));
              }
            });
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error loading state: $e');
        }
      }
    }
  }

  Future<void> _clearState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hotgeo_state');
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing state: $e');
      }
    }
  }

  LocationChallenge? _getDailyChallenge() {
    if (_allChallenges == null || _allChallenges!.isEmpty) {
      return null;
    }

    // Epoch date: January 1, 2025 (when we start the daily challenges)
    final epoch = DateTime(2025, 1, 1);
    final now = DateTime.now();

    // Calculate days since epoch
    final daysSinceEpoch = now.difference(epoch).inDays;

    // Use modulo to cycle through all 365 locations
    // Each location has an "id" field from 1-365
    final dailyLocationId = (daysSinceEpoch % 365) + 1;

    // Find the location with this ID
    try {
      return _allChallenges!.firstWhere(
        (challenge) => challenge.id == dailyLocationId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error finding daily challenge for ID $dailyLocationId: $e');
      }
      // Fallback to first location if something goes wrong
      return _allChallenges!.first;
    }
  }

  Future<void> _initializeLocationProgression() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedLocationId = prefs.getInt('currentLocationId');

      // Get daily challenge ID
      final dailyChallengeId = _getDailyChallengeId();

      // Use stored progression if it's ahead of today's challenge, otherwise start from today
      _currentLocationId = (storedLocationId != null && storedLocationId > dailyChallengeId)
          ? storedLocationId
          : dailyChallengeId;
    } catch (e) {
      // Default to daily challenge if anything fails
      _currentLocationId = _getDailyChallengeId();
    }
  }

  int _getDailyChallengeId() {
    // Epoch date: January 1, 2025 (when we start the daily challenges)
    final epoch = DateTime(2025, 1, 1);
    final now = DateTime.now();
    final daysSinceEpoch = now.difference(epoch).inDays;
    return (daysSinceEpoch % 365) + 1;
  }

  LocationChallenge? _getCurrentChallenge() {
    if (_allChallenges == null || _allChallenges!.isEmpty) {
      return null;
    }

    try {
      return _allChallenges!.firstWhere(
        (challenge) => challenge.id == _currentLocationId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error finding challenge for ID $_currentLocationId: $e');
      }
      return _allChallenges!.first;
    }
  }

  Future<LocationChallenge?> _getNextChallenge() async {
    if (_allChallenges == null || _allChallenges!.isEmpty) {
      return null;
    }

    // Increment and wrap around
    _currentLocationId = (_currentLocationId % 365) + 1;

    // Save progression
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('currentLocationId', _currentLocationId);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving location progression: $e');
      }
    }

    return _getCurrentChallenge();
  }

  // Load metadata for the current location (for discovery card)
  Future<void> _loadLocationMetadata() async {
    if (_challenge == null) return;

    try {
      // Build the metadata file path based on location ID and name
      final locationId = _challenge!.id.toString().padLeft(3, '0');
      final locationName = _challenge!.name.toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll("'", '')
          .replaceAll(',', '')
          .replaceAll('.', '');

      // Try multiple filename patterns
      final patterns = [
        'assets/location_backgrounds/metadata/${locationId}_${locationName}_metadata.json',
        'assets/location_backgrounds/metadata/${locationId}_${_challenge!.name.toLowerCase().replaceAll(' ', '_')}_metadata.json',
      ];

      String? jsonString;
      for (final pattern in patterns) {
        try {
          jsonString = await rootBundle.loadString(pattern);
          break;
        } catch (_) {
          // Try next pattern
        }
      }

      if (jsonString != null) {
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        setState(() {
          _locationMetadata = LocationMetadata.fromJson(jsonData);
        });
      } else {
        if (kDebugMode) {
          print('No metadata found for location: ${_challenge!.name}');
        }
        setState(() {
          _locationMetadata = null;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading location metadata: $e');
      }
      setState(() {
        _locationMetadata = null;
      });
    }
  }

  // Get background image path for current location
  String? _getBackgroundImagePath() {
    if (_challenge == null) return null;

    final locationId = _challenge!.id.toString().padLeft(3, '0');
    final locationName = _challenge!.name.toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll("'", '')
        .replaceAll(',', '')
        .replaceAll('.', '');

    return 'assets/location_backgrounds/${locationId}_$locationName.png';
  }

  Future<void> _loadSessionStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load win streak
      _winStreak = prefs.getInt('hotgeo_winStreak') ?? 0;

      // Load recent games
      final recentGamesJson = prefs.getString('hotgeo_recentGames');
      if (recentGamesJson != null) {
        final List<dynamic> gamesList = json.decode(recentGamesJson);
        _recentGames = gamesList.map((g) => GameResult.fromJson(g)).toList();

        // Only keep last 10 games
        if (_recentGames.length > 10) {
          _recentGames = _recentGames.sublist(_recentGames.length - 10);
        }
      }

      // Calculate today's stats
      final today = DateTime.now();
      final todayGames = _recentGames.where((g) {
        return g.timestamp.year == today.year &&
               g.timestamp.month == today.month &&
               g.timestamp.day == today.day;
      }).toList();

      _todayGames = todayGames.length;
      _todayWins = todayGames.where((g) => g.won).length;

      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print('Error loading session stats: $e');
      }
    }
  }

  Future<void> _saveSessionStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save win streak
      await prefs.setInt('hotgeo_winStreak', _winStreak);

      // Save recent games (keep last 10)
      final gamesToSave = _recentGames.length > 10
          ? _recentGames.sublist(_recentGames.length - 10)
          : _recentGames;
      await prefs.setString(
        'hotgeo_recentGames',
        json.encode(gamesToSave.map((g) => g.toJson()).toList()),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving session stats: $e');
      }
    }
  }

  void _recordGameResult(bool won) {
    final attempts = 6 - _attemptsLeft;

    // Update streak
    if (won) {
      _winStreak++;
      _todayWins++;
    } else {
      _winStreak = 0; // Reset streak on loss
    }
    _todayGames++;

    // Add to recent games
    final result = GameResult(
      locationName: _challenge!.name,
      difficulty: _challenge!.difficulty,
      won: won,
      attempts: attempts,
      timestamp: DateTime.now(),
    );
    _recentGames.add(result);

    // Save stats
    _saveSessionStats();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while challenges are being loaded
    if (_isLoading || _challenge == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1D428A)),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading locations...',
                style: TextStyle(
                  fontSize: 18,
                  color: const Color(0xFF1D428A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: screenWidth < 600
          ? _buildMobileLayout()
          : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // Full-screen map as base layer
        _buildMap(),

        // Top overlay bar
        _buildTopOverlay(),

        // Map control buttons (bottom-left)
        _buildMapControls(),

        // Floating action buttons (bottom-right)
        _buildFloatingButtons(),

        // Draggable bottom sheet for feedback
        _buildBottomSheet(),

        // Discovery card overlay (shown when player wins)
        if (_showDiscoveryCard)
          _buildDiscoveryCard(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    // Desktop also uses overlay design for consistency
    return Stack(
      children: [
        // Full-screen map as base layer
        _buildMap(),

        // Top overlay bar
        _buildTopOverlay(),

        // Map control buttons (bottom-left)
        _buildMapControls(),

        // Floating action buttons (bottom-right)
        _buildFloatingButtons(),

        // Draggable bottom sheet for feedback (wider on desktop)
        _buildBottomSheet(),

        // Discovery card overlay (shown when player wins)
        if (_showDiscoveryCard)
          _buildDiscoveryCard(),
      ],
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1D428A).withOpacity(0.05),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'HotGeo',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D428A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (_winStreak > 0) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFF44336)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '🔥',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_winStreak',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Text(
                    'Attempts: $_attemptsLeft/6',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 16),
                  Image.asset(
                    'assets/logo.png',
                    height: 75,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Mobile layout: Difficulty badge on top, controls below
          if (isMobile) ...[
            // Difficulty badge row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _getDifficultyColor(), width: 2),
                  ),
                  child: Text(
                    _getDifficultyLabel(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getDifficultyColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Main controls row with Flexible widgets for better spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D428A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1D428A), width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.place, color: Color(0xFF1D428A), size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Find: ${_challenge!.name}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D428A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showHint,
                  icon: const Icon(Icons.lightbulb_outline, size: 16),
                  label: Text(_hintUsed ? 'Hint' : 'Hint'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hintUsed ? const Color(0xFF1D428A).withOpacity(0.5) : const Color(0xFF1D428A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _guesses.isEmpty ? null : () {
                    setState(() {
                      _showRadiusHint = !_showRadiusHint;
                    });
                    _saveState();
                  },
                  icon: Icon(
                    _showRadiusHint ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 16,
                  ),
                  label: const Text('Radius'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showRadiusHint ? const Color(0xFF1D428A) : const Color(0xFF1D428A).withOpacity(0.7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Desktop layout: All in one row (original layout)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Difficulty badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _getDifficultyColor(), width: 2),
                  ),
                  child: Text(
                    _getDifficultyLabel(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getDifficultyColor(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D428A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1D428A), width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place, color: Color(0xFF1D428A), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Find: ${_challenge!.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D428A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showHint,
                  icon: const Icon(Icons.lightbulb_outline, size: 18),
                  label: Text(_hintUsed ? 'Hint Used' : 'Hint'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hintUsed ? const Color(0xFF1D428A).withOpacity(0.5) : const Color(0xFF1D428A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 12),
                // Radius hint toggle button
                ElevatedButton.icon(
                  onPressed: _guesses.isEmpty ? null : () {
                    setState(() {
                      _showRadiusHint = !_showRadiusHint;
                    });
                    _saveState(); // Save radius toggle state
                  },
                  icon: Icon(
                    _showRadiusHint ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 18,
                  ),
                  label: const Text('Radius'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showRadiusHint ? const Color(0xFF1D428A) : const Color(0xFF1D428A).withOpacity(0.7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopOverlay() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final gameEnded = _attemptsLeft == 0 || (_lastDistance != null && _lastDistance! < _challenge!.winThresholdKm);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20,
          vertical: isMobile ? 8 : 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Attempts and Location
              Expanded(
                child: Row(
                  children: [
                    Text(
                      '$_attemptsLeft/6',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1D428A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 12,
                          vertical: isMobile ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF1D428A),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.place,
                              color: const Color(0xFF1D428A),
                              size: isMobile ? 14 : 16,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _challenge!.name,
                                style: TextStyle(
                                  fontSize: isMobile ? 13 : 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1D428A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Right side: Difficulty badge and streak
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 6 : 8,
                      vertical: isMobile ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _getDifficultyColor(), width: 1.5),
                    ),
                    child: Text(
                      _getDifficultyLabel(),
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 13,
                        fontWeight: FontWeight.bold,
                        color: _getDifficultyColor(),
                      ),
                    ),
                  ),
                  if (_winStreak > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 6 : 8,
                        vertical: isMobile ? 3 : 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFF44336)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🔥',
                            style: TextStyle(fontSize: isMobile ? 12 : 14),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$_winStreak',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButtons() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final bottomSheetOffset = isMobile ? 200.0 : 250.0; // Leave space for bottom sheet

    return Positioned(
      right: isMobile ? 12 : 20,
      bottom: bottomSheetOffset,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hint button
          FloatingActionButton(
            heroTag: 'hint',
            onPressed: _showHint,
            backgroundColor: _hintUsed
              ? const Color(0xFF1D428A).withOpacity(0.5)
              : const Color(0xFF1D428A),
            child: const Icon(Icons.lightbulb_outline, color: Colors.white),
          ),
          const SizedBox(height: 12),
          // Radius toggle button
          FloatingActionButton(
            heroTag: 'radius',
            onPressed: _guesses.isEmpty ? null : () {
              setState(() {
                _showRadiusHint = !_showRadiusHint;
              });
              _saveState();
            },
            backgroundColor: _showRadiusHint
              ? const Color(0xFF1D428A)
              : const Color(0xFF1D428A).withOpacity(0.7),
            child: Icon(
              _showRadiusHint ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final buttonSize = isMobile ? 28.0 : 32.0;
    final iconSize = isMobile ? 14.0 : 16.0;

    Widget buildControlButton(IconData icon, VoidCallback onPressed, String semanticLabel) {
      return SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: FloatingActionButton(
          heroTag: semanticLabel,
          mini: true,
          onPressed: onPressed,
          backgroundColor: const Color(0xFF1D428A).withOpacity(0.25),
          child: Icon(icon, color: Colors.white.withOpacity(0.9), size: iconSize),
        ),
      );
    }

    return Positioned(
      left: isMobile ? 12 : 20,
      bottom: isMobile ? 200.0 : 250.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom controls
          buildControlButton(Icons.add, _zoomIn, 'zoom_in'),
          const SizedBox(height: 4),
          buildControlButton(Icons.remove, _zoomOut, 'zoom_out'),
          const SizedBox(height: 16),
          // Directional controls - Cross pattern
          Column(
            children: [
              buildControlButton(Icons.arrow_upward, _panNorth, 'pan_north'),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildControlButton(Icons.arrow_back, _panWest, 'pan_west'),
                  SizedBox(width: buttonSize),
                  buildControlButton(Icons.arrow_forward, _panEast, 'pan_east'),
                ],
              ),
              const SizedBox(height: 4),
              buildControlButton(Icons.arrow_downward, _panSouth, 'pan_south'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final gameEnded = _attemptsLeft == 0 ||
      (_lastDistance != null && _lastDistance! < _challenge!.winThresholdKm);

    return DraggableScrollableSheet(
      initialChildSize: gameEnded ? 0.35 : 0.12, // Auto-expand when game ends
      minChildSize: 0.08,
      maxChildSize: 0.6,
      snap: true,
      snapSizes: const [0.12, 0.35, 0.6],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Feedback panel content (reusing existing)
              _buildFeedbackPanelContent(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedbackPanelContent() {
    final gameEnded = _attemptsLeft == 0 ||
      (_lastDistance != null && _lastDistance! < _challenge!.winThresholdKm);
    final isMobile = MediaQuery.of(context).size.width < 768;

    // Adaptive sizing based on screen size
    final containerPadding = isMobile ? 12.0 : 20.0;
    final feedbackPadding = isMobile ? 8.0 : 16.0;
    final feedbackFontSize = isMobile ? 16.0 : 20.0;
    final distanceFontSize = isMobile ? 14.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Feedback message with distance
        Container(
          padding: EdgeInsets.all(feedbackPadding),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                _feedback,
                style: TextStyle(
                  fontSize: feedbackFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1D428A),
                ),
                textAlign: TextAlign.center,
              ),
              if (_lastDistance != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${_lastDistance!.toStringAsFixed(0)} km away',
                  style: TextStyle(
                    fontSize: distanceFontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1D428A).withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Play Again button (prominent, shown when game ended)
        if (gameEnded)
          ElevatedButton.icon(
            onPressed: _resetGame,
            icon: Icon(Icons.refresh, size: isMobile ? 20 : 24),
            label: Text(
              'Play Again',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D428A),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 32,
                vertical: isMobile ? 16 : 20,
              ),
              minimumSize: Size(isMobile ? 200 : 250, isMobile ? 50 : 60),
            ),
          ),

        if (gameEnded) const SizedBox(height: 12),

        // Discover button (only show when player WON)
        if (gameEnded && _lastDistance != null && _lastDistance! < _challenge!.winThresholdKm)
          ElevatedButton.icon(
            onPressed: _showLocationDiscoveryCard,
            icon: const Icon(Icons.explore),
            label: const Text('Discover'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 24,
                vertical: isMobile ? 12 : 16,
              ),
              textStyle: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        if (gameEnded && _lastDistance != null && _lastDistance! < _challenge!.winThresholdKm)
          const SizedBox(height: 12),

        // Share button (only show when game ended)
        if (gameEnded)
          ElevatedButton.icon(
            onPressed: _shareResults,
            icon: const Icon(Icons.share),
            label: const Text('Share Results'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D428A),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 24,
                vertical: isMobile ? 12 : 16,
              ),
              textStyle: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        if (gameEnded) const SizedBox(height: 16),

        // Guess history
        if (_guesses.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Guesses (${_guesses.length}/6)',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1D428A),
                ),
              ),
              if (isMobile && _guesses.length > 3)
                IconButton(
                  icon: Icon(
                    _guessHistoryExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: const Color(0xFF1D428A),
                  ),
                  onPressed: () {
                    setState(() {
                      _guessHistoryExpanded = !_guessHistoryExpanded;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(
            (isMobile && !_guessHistoryExpanded) ? min(3, _guesses.length) : _guesses.length,
            (index) {
              final dist = _calculateDistance(_guesses[index], _challenge!.coordinates);
              return Padding(
                padding: EdgeInsets.symmetric(vertical: isMobile ? 2 : 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.circle,
                      color: _getMarkerColor(index),
                      size: isMobile ? 12 : 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '#${index + 1}: ${dist.toStringAsFixed(0)} km',
                      style: TextStyle(fontSize: isMobile ? 12 : 14),
                    ),
                  ],
                ),
              );
            },
          ),
          if (isMobile && !_guessHistoryExpanded && _guesses.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... +${_guesses.length - 3} more',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ],
    );
  }

  LatLng _getRandomOffsetStart() {
    // Generate random offset based on difficulty
    // This prevents the map from starting centered on the answer!
    final random = Random(_challenge!.name.hashCode); // Consistent per location

    // Offset distance in kilometers based on difficulty
    double offsetKm;
    if (_challenge!.difficulty == 'easy') {
      offsetKm = 500 + random.nextDouble() * 500; // 500-1000km
    } else if (_challenge!.difficulty == 'medium') {
      offsetKm = 1000 + random.nextDouble() * 1000; // 1000-2000km
    } else {
      offsetKm = 2000 + random.nextDouble() * 3000; // 2000-5000km
    }

    // Random direction (bearing in degrees)
    final bearing = random.nextDouble() * 360;

    // Calculate offset position using distance and bearing
    const Distance distance = Distance();
    final offset = distance.offset(
      _challenge!.coordinates,
      offsetKm * 1000, // Convert to meters
      bearing,
    );

    return offset;
  }

  Widget _buildMap() {
    return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _getRandomOffsetStart(), // NOT centered on answer!
            initialZoom: _challenge!.initialZoom,
            onTap: _handleMapTap,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.hotgeo.app',
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
            // Radius hint circle (centered on latest guess)
            // Shows distance to target with 30% margin for visibility
            if (_showRadiusHint && _guesses.isNotEmpty && _lastDistance != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _guesses.last,
                    radius: _lastDistance! * 1000 * 1.3, // km to meters, +30% margin
                    useRadiusInMeter: true,
                    color: Colors.blue.withOpacity(0.15),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 4,
                  ),
                ],
              ),
            // Show target after game ends
            if (_attemptsLeft == 0 || (_lastDistance != null && _lastDistance! < _challenge!.winThresholdKm))
              MarkerLayer(
                markers: [
                  Marker(
                    point: _challenge!.coordinates,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 50,
                    ),
                  ),
                ],
              ),
            // Distance scale indicator
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  border: Border.all(color: const Color(0xFF1D428A), width: 2),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 4,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: const Color(0xFF1D428A), width: 2),
                          left: BorderSide(color: const Color(0xFF1D428A), width: 2),
                          right: BorderSide(color: const Color(0xFF1D428A), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getScaleText(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D428A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
    );
  }

  // Map control methods
  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  void _panNorth() {
    final center = _mapController.camera.center;
    final newCenter = LatLng(center.latitude + 5, center.longitude);
    _mapController.move(newCenter, _mapController.camera.zoom);
  }

  void _panSouth() {
    final center = _mapController.camera.center;
    final newCenter = LatLng(center.latitude - 5, center.longitude);
    _mapController.move(newCenter, _mapController.camera.zoom);
  }

  void _panEast() {
    final center = _mapController.camera.center;
    final newCenter = LatLng(center.latitude, center.longitude + 5);
    _mapController.move(newCenter, _mapController.camera.zoom);
  }

  void _panWest() {
    final center = _mapController.camera.center;
    final newCenter = LatLng(center.latitude, center.longitude - 5);
    _mapController.move(newCenter, _mapController.camera.zoom);
  }

  void _handleMapTap(TapPosition tapPos, LatLng point) {
    if (_attemptsLeft <= 0) return;
    if (_lastDistance != null && _lastDistance! < _challenge!.winThresholdKm) return;

    final distance = _calculateDistance(point, _challenge!.coordinates);
    final isWin = distance < _challenge!.winThresholdKm;

    setState(() {
      _guesses.add(point);
      _attemptsLeft--;
      _lastDistance = distance;
      _feedback = _generateFeedback(_lastDistance!);

      if (isWin) { // WIN!
        _feedback = "🎉 YOU FOUND IT!\nDistance: ${_lastDistance!.toStringAsFixed(0)}km";
      } else if (_attemptsLeft == 0) {
        _feedback = "💀 Game Over!\nThe location is now revealed on the map.";
      }
    });
    _saveState(); // Save progress after each guess

    // Show discovery card on win (after a short delay for dramatic effect)
    if (isWin) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _showLocationDiscoveryCard();
        }
      });
    }
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, p1, p2);
  }

  String _generateFeedback(double distance) {
    // Feedback matches the gamer-focused gradient logic
    final threshold = _challenge!.winThresholdKm;

    // Match the color gradient thresholds for consistency
    if (threshold >= 50) {  // EASY MODE
      if (distance <= threshold) return "🔥 VICTORY ZONE!\nYou're basically there!";
      if (distance <= threshold * 2) return "🔥 BURNING HOT!\nSo close!";
      if (distance <= threshold * 6) return "🌡️ Very hot!\nYou're in the right area.";
      if (distance <= threshold * 10) return "♨️ Getting warm!\nNarrowing it down.";
      if (distance <= threshold * 20) return "🧊 Cool...\nYou're in the region.";
      if (distance <= threshold * 50) return "❄️ Cold...\nStill far away.";
      return "🧊 Freezing cold!\nVery far away.";
    } else if (threshold >= 25) {  // MEDIUM MODE
      if (distance <= threshold) return "🔥 VICTORY ZONE!\nYou're basically there!";
      if (distance <= threshold * 3) return "🔥 BURNING HOT!\nAlmost there!";
      if (distance <= threshold * 8) return "🌡️ Very hot!\nRight area!";
      if (distance <= threshold * 16) return "♨️ Getting warm!\nNarrowing down.";
      if (distance <= threshold * 30) return "🧊 Cool...\nIn the region.";
      if (distance <= threshold * 80) return "❄️ Cold...\nStill searching.";
      return "🧊 Freezing cold!\nVery far away.";
    } else {  // HARD MODE
      if (distance <= threshold) return "🔥 VICTORY ZONE!\nYou're basically there!";
      if (distance <= threshold * 3) return "🔥 BURNING HOT!\nSo close!";
      if (distance <= threshold * 10) return "🌡️ Very hot!\nAlmost there!";
      if (distance <= threshold * 30) return "♨️ Getting warm!\nClosing in.";
      if (distance <= threshold * 50) return "🧊 Cool...\nKeep searching.";
      if (distance <= threshold * 150) return "❄️ Cold...\nStill far.";
      return "🧊 Freezing cold!\nVery far away.";
    }
  }

  String _getScaleText() {
    // Calculate scale based on current zoom level
    // Web Mercator projection: meters per pixel = Earth circumference / (256 * 2^zoom)
    try {
      final zoom = _mapController.camera.zoom;
      const earthCircumference = 40075017.0; // meters at equator
      final metersPerPixel = earthCircumference / (256 * pow(2, zoom));

      // Scale bar is 100 pixels wide
      final scaleMeters = metersPerPixel * 100;
      final scaleKm = scaleMeters / 1000;

      // Round to nice numbers
      if (scaleKm >= 1000) {
        return '${(scaleKm / 1000).toStringAsFixed(0)}000 km';
      } else if (scaleKm >= 100) {
        return '${(scaleKm / 100).round() * 100} km';
      } else if (scaleKm >= 10) {
        return '${(scaleKm / 10).round() * 10} km';
      } else if (scaleKm >= 1) {
        return '${scaleKm.round()} km';
      } else {
        return '${(scaleMeters / 100).round() * 100} m';
      }
    } catch (e) {
      // Map not ready yet, return default
      return '100 km';
    }
  }

  Color _getMarkerColor(int index) {
    if (index >= _guesses.length) return Colors.grey;
    final distance = _calculateDistance(_guesses[index], _challenge!.coordinates);
    final threshold = _challenge!.winThresholdKm;

    // GAMER-FOCUSED GRADIENT: Designed from player psychology!
    // Key insight: "400km MUST be yellow, not blue!"
    // 95.8% accuracy against gamer expectations, 0 critical failures

    if (distance <= threshold) return Colors.red;

    // Different multipliers for different difficulties
    // Ensures progression feels rewarding throughout the game

    if (threshold >= 50) {  // EASY MODE (Mumbai, major cities)
      // Red: 0-100km (2x), Orange: 100-300km (6x), Yellow: 300-500km (10x)
      if (distance <= threshold * 2) return Colors.red;        // 0-100km
      if (distance <= threshold * 6) return Colors.orange;     // 100-300km
      if (distance <= threshold * 10) return Colors.yellow;    // 300-500km ← 400km FIX!
      if (distance <= threshold * 20) return Colors.lightBlue; // 500-1000km
      if (distance <= threshold * 50) return Colors.blue;      // 1000-2500km
      return const Color(0xFF1565C0);                          // 2500km+ (dark blue)

    } else if (threshold >= 25) {  // MEDIUM MODE (Barcelona, medium cities)
      // Red: 0-75km (3x), Orange: 75-200km (8x), Yellow: 200-400km (16x)
      if (distance <= threshold * 3) return Colors.red;        // 0-75km
      if (distance <= threshold * 8) return Colors.orange;     // 75-200km
      if (distance <= threshold * 16) return Colors.yellow;    // 200-400km ← 400km FIX!
      if (distance <= threshold * 30) return Colors.lightBlue; // 400-750km
      if (distance <= threshold * 80) return Colors.blue;      // 750-2000km
      return const Color(0xFF1565C0);                          // 2000km+ (dark blue)

    } else {  // HARD MODE (Innsbruck, small cities - 10km threshold)
      // Red: 0-30km (3x), Orange: 30-100km (10x), Yellow: 100-300km (30x)
      if (distance <= threshold * 3) return Colors.red;        // 0-30km
      if (distance <= threshold * 10) return Colors.orange;    // 30-100km
      if (distance <= threshold * 30) return Colors.yellow;    // 100-300km
      if (distance <= threshold * 50) return Colors.lightBlue; // 300-500km ← 400km is light_blue
      if (distance <= threshold * 150) return Colors.blue;     // 500-1500km
      return const Color(0xFF1565C0);                          // 1500km+ (dark blue)
    }
  }

  void _showHint() {
    if (!_hintUsed) {
      setState(() {
        _hintUsed = true;
      });
    }

    final country = _challenge!.hints['country'] ?? 'Unknown';
    final region = _challenge!.hints['region'] ?? '';
    final hintText = region.isNotEmpty ? '$country\n$region' : country;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1D428A), width: 2),
        ),
        title: Row(
          children: const [
            Icon(Icons.lightbulb, color: Color(0xFF1D428A)),
            SizedBox(width: 8),
            Text(
              'Hint',
              style: TextStyle(
                color: Color(0xFF1D428A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          hintText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D428A),
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Got it!',
              style: TextStyle(
                color: Color(0xFF1D428A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _generateShareText() {
    // Get last 10 games (or fewer if not enough games played)
    final recentToShow = _recentGames.length > 10
        ? _recentGames.sublist(_recentGames.length - 10)
        : _recentGames;

    // Build streak line
    String streakLine = '';
    if (_winStreak > 0) {
      streakLine = '🔥 $_winStreak streak';
    }

    // Group games by difficulty
    Map<String, List<String>> difficultyGroups = {
      'easy': [],
      'medium': [],
      'hard': [],
    };

    for (final game in recentToShow) {
      final result = game.won ? '${game.attempts}/6' : '💀';
      difficultyGroups[game.difficulty]?.add(result);
    }

    // Build difficulty lines
    String difficultyText = '';
    if (difficultyGroups['easy']!.isNotEmpty) {
      difficultyText += '🟢 Easy: ${difficultyGroups['easy']!.join(' ')}\n';
    }
    if (difficultyGroups['medium']!.isNotEmpty) {
      difficultyText += '🟡 Medium: ${difficultyGroups['medium']!.join(' ')}\n';
    }
    if (difficultyGroups['hard']!.isNotEmpty) {
      difficultyText += '🔴 Hard: ${difficultyGroups['hard']!.join(' ')}\n';
    }

    // Build final share text
    String shareText = 'HotGeo 🗺️\n';
    if (streakLine.isNotEmpty) {
      shareText += '$streakLine\n\n';
    }
    if (difficultyText.isNotEmpty) {
      shareText += difficultyText;
    }
    shareText += '\nhttps://hotgeo.us';

    return shareText;
  }

  Future<void> _shareResults() async {
    // Record current game result if not already recorded
    if (_challenge != null && _guesses.isNotEmpty) {
      final gameEnded = _attemptsLeft == 0 || (_lastDistance != null && _lastDistance! < _challenge!.winThresholdKm);
      if (gameEnded) {
        // Check if this game is already in recent games (to avoid duplicates)
        final currentGameAlreadyRecorded = _recentGames.isNotEmpty &&
          _recentGames.last.locationName == _challenge!.name &&
          _recentGames.last.attempts == (6 - _attemptsLeft);

        if (!currentGameAlreadyRecorded) {
          final won = _lastDistance != null && _lastDistance! < _challenge!.winThresholdKm;
          _recordGameResult(won);
        }
      }
    }

    final text = _generateShareText();

    try {
      // Check if Web Share API is available (mobile browsers)
      if (kIsWeb && js_util.hasProperty(html.window.navigator, 'share')) {
        // Use native share sheet
        await js_util.promiseToFuture(
          js_util.callMethod(
            html.window.navigator,
            'share',
            [
              js_util.jsify({
                'text': text,
              })
            ],
          ),
        );
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Web Share API failed, falling back to clipboard: $e');
      }
    }

    // Fallback: Copy to clipboard (desktop browsers)
    try {
      await Clipboard.setData(ClipboardData(text: text));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Results copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error copying to clipboard: $e');
      }
    }
  }

  Widget _buildFeedbackPanel() {
    final gameEnded = _attemptsLeft == 0 || (_lastDistance != null && _lastDistance! < _challenge!.winThresholdKm);
    final isMobile = MediaQuery.of(context).size.width < 768;

    // Adaptive sizing based on screen size
    final containerPadding = isMobile ? 12.0 : 20.0;
    final feedbackPadding = isMobile ? 8.0 : 16.0;
    final feedbackFontSize = isMobile ? 16.0 : 20.0;
    final distanceFontSize = isMobile ? 14.0 : 18.0;
    final historyFontSize = isMobile ? 12.0 : 14.0;
    final buttonPaddingH = isMobile ? 16.0 : 24.0;
    final buttonPaddingV = isMobile ? 8.0 : 12.0;

    return Container(
      padding: EdgeInsets.all(containerPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Compact feedback message with inline distance
          Container(
            padding: EdgeInsets.all(feedbackPadding),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border.all(color: const Color(0xFF1D428A), width: isMobile ? 1.5 : 2),
              borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D428A).withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _feedback,
                  style: TextStyle(
                    fontSize: feedbackFontSize,
                    fontWeight: FontWeight.bold,
                    height: isMobile ? 1.2 : 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_lastDistance != null) ...[
                  SizedBox(height: isMobile ? 4 : 8),
                  Text(
                    '${_lastDistance!.toStringAsFixed(0)} km away',
                    style: TextStyle(
                      fontSize: distanceFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D428A),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Collapsible guess history (only show last 3 on mobile by default)
          if (_guesses.isNotEmpty) ...[
            SizedBox(height: isMobile ? 12 : 24),
            _buildCompactGuessHistory(isMobile, historyFontSize),
          ],

          // Action buttons (horizontal on mobile when space permits)
          if (gameEnded) ...[
            SizedBox(height: isMobile ? 12 : 20),
            if (isMobile && MediaQuery.of(context).size.width > 400)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _resetGame,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Play Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D428A),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: buttonPaddingH, vertical: buttonPaddingV),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareResults,
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1D428A),
                        side: BorderSide(color: const Color(0xFF1D428A), width: isMobile ? 1.5 : 2),
                        padding: EdgeInsets.symmetric(horizontal: buttonPaddingH, vertical: buttonPaddingV),
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              ElevatedButton.icon(
                onPressed: _resetGame,
                icon: Icon(Icons.refresh, size: isMobile ? 18 : 20),
                label: const Text('Play Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D428A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: buttonPaddingH, vertical: buttonPaddingV),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _shareResults,
                icon: Icon(Icons.share, size: isMobile ? 18 : 20),
                label: const Text('Share Score'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1D428A),
                  side: BorderSide(color: const Color(0xFF1D428A), width: isMobile ? 1.5 : 2),
                  padding: EdgeInsets.symmetric(horizontal: buttonPaddingH, vertical: buttonPaddingV),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCompactGuessHistory(bool isMobile, double fontSize) {
    final maxVisible = isMobile ? 3 : 6;
    final showAll = _guessHistoryExpanded || !isMobile || _guesses.length <= maxVisible;
    final guessesToShow = showAll ? _guesses.length : maxVisible.clamp(0, _guesses.length);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compact header with expand button on mobile
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Guesses (${_guesses.length}/6)',
              style: TextStyle(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isMobile && _guesses.length > maxVisible) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  _guessHistoryExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: const Color(0xFF1D428A),
                ),
                onPressed: () {
                  setState(() {
                    _guessHistoryExpanded = !_guessHistoryExpanded;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        // Compact guess list
        ...List.generate(guessesToShow, (index) {
          final dist = _calculateDistance(_guesses[index], _challenge!.coordinates);
          return Padding(
            padding: EdgeInsets.symmetric(vertical: isMobile ? 2 : 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  color: _getMarkerColor(index),
                  size: isMobile ? 12 : 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '#${index + 1}: ${dist.toStringAsFixed(0)} km',
                  style: TextStyle(fontSize: fontSize),
                ),
              ],
            ),
          );
        }),
        if (isMobile && !showAll && _guesses.length > maxVisible) ...[
          Text(
            '... +${_guesses.length - maxVisible} more',
            style: TextStyle(
              fontSize: fontSize - 1,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  String _getDifficultyLabel() {
    final threshold = _challenge!.winThresholdKm;
    if (threshold >= 50) return '⭐ Easy';
    if (threshold >= 25) return '⭐⭐ Medium';
    return '⭐⭐⭐ Hard';
  }

  Color _getDifficultyColor() {
    final threshold = _challenge!.winThresholdKm;
    if (threshold >= 50) return const Color(0xFF4CAF50); // Green for easy
    if (threshold >= 25) return const Color(0xFFFF9800); // Orange for medium
    return const Color(0xFFF44336); // Red for hard
  }

  // Show the discovery card when player wins
  void _showLocationDiscoveryCard() {
    _loadLocationMetadata();
    setState(() {
      _showDiscoveryCard = true;
      _discoveryCardPage = 0;
    });
  }

  // Build the discovery card overlay
  Widget _buildDiscoveryCard() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showDiscoveryCard = false;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent tap-through
            child: Container(
              width: isMobile ? screenWidth * 0.95 : min(500.0, screenWidth * 0.8),
              height: isMobile ? screenHeight * 0.85 : screenHeight * 0.8,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Background image
                    _buildBackgroundImage(),

                    // Gradient overlay for readability (lighter to let image show through)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.6),
                          ],
                          stops: const [0.0, 0.3, 0.6, 1.0],
                        ),
                      ),
                    ),

                    // Content
                    Column(
                      children: [
                        // Close button and header
                        _buildCardHeader(isMobile),

                        // Main scrollable content
                        Expanded(
                          child: _buildCardContent(isMobile),
                        ),

                        // Page indicator dots
                        _buildPageIndicator(isMobile),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundImage() {
    final imagePath = _getBackgroundImagePath();

    return Positioned.fill(
      child: imagePath != null
          ? Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1D428A),
                        const Color(0xFF3D5A9B),
                        const Color(0xFF5C7FB8),
                      ],
                    ),
                  ),
                );
              },
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1D428A),
                    const Color(0xFF3D5A9B),
                    const Color(0xFF5C7FB8),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCardHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOU FOUND IT!',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _challenge?.name ?? '',
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                if (_locationMetadata != null)
                  Text(
                    _locationMetadata!.country,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 20,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          // Close button
          IconButton(
            onPressed: () {
              setState(() {
                _showDiscoveryCard = false;
              });
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(bool isMobile) {
    return PageView(
      onPageChanged: (index) {
        setState(() {
          _discoveryCardPage = index;
        });
      },
      children: [
        // Page 1: Fun Fact
        _buildFunFactPage(isMobile),

        // Page 2: Places to See (Landmarks & Atmosphere)
        if (_locationMetadata?.visualElements != null &&
            (_locationMetadata!.visualElements!.landmarks.isNotEmpty ||
             _locationMetadata!.visualElements!.uniqueModern.isNotEmpty))
          _buildPlacesPage(isMobile),

        // Page 3: Food & Dishes
        if (_locationMetadata?.foodAndDrink != null &&
            _locationMetadata!.foodAndDrink!.heroDishes.isNotEmpty)
          _buildFoodPage(isMobile),

        // Page 4: Drinks & Culture
        if (_locationMetadata?.foodAndDrink != null &&
            (_locationMetadata!.foodAndDrink!.signatureDrinks.isNotEmpty ||
             _locationMetadata!.foodAndDrink!.foodCultureNotes.isNotEmpty))
          _buildDrinksPage(isMobile),
      ],
    );
  }

  Widget _buildFunFactPage(bool isMobile) {
    final funFact = _locationMetadata?.funFact ?? 'No fun fact available for this location yet.';

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fun fact card
          Container(
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D428A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.lightbulb,
                        color: Color(0xFFFFB300),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Did You Know?',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1D428A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  funFact,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    height: 1.6,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Game stats
          _buildGameStats(isMobile),

          const SizedBox(height: 16),

          // Swipe hint
          Center(
            child: Text(
              'Swipe for more',
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: Colors.white.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacesPage(bool isMobile) {
    final landmarks = _locationMetadata?.visualElements?.landmarks ?? [];
    final atmosphere = _locationMetadata?.visualElements?.atmosphere ?? [];
    final uniqueModern = _locationMetadata?.visualElements?.uniqueModern ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Landmarks section
          if (landmarks.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.location_city,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Must-See Places',
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...landmarks.map((landmark) => _buildPlaceItem(landmark, Icons.place, isMobile)).toList(),
          ],

          // Unique/Modern attractions
          if (uniqueModern.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Don\'t Miss',
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...uniqueModern.map((item) => _buildPlaceItem(item, Icons.star, isMobile)).toList(),
          ],

          // Atmosphere section
          if (atmosphere.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.mood,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'The Vibe',
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: atmosphere.map((vibe) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lens,
                        size: 8,
                        color: const Color(0xFF1D428A),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          vibe,
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceItem(String text, IconData icon, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: isMobile ? 20 : 24,
            color: const Color(0xFF1D428A),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStats(bool isMobile) {
    final attempts = 6 - _attemptsLeft;
    final distance = _lastDistance?.toStringAsFixed(0) ?? '?';

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Attempts', '$attempts/6', Icons.touch_app, isMobile),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStatItem('Distance', '${distance}km', Icons.place, isMobile),
          if (_winStreak > 1) ...[
            Container(
              width: 1,
              height: 40,
              color: Colors.white.withOpacity(0.3),
            ),
            _buildStatItem('Streak', '$_winStreak', Icons.local_fire_department, isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isMobile) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: isMobile ? 20 : 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 11 : 13,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodPage(bool isMobile) {
    final dishes = _locationMetadata?.foodAndDrink?.heroDishes ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Icon(
                Icons.restaurant,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Local Cuisine',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Dish cards
          ...dishes.map((dish) => _buildDishCard(dish, isMobile)).toList(),
        ],
      ),
    );
  }

  Widget _buildDishCard(HeroDish dish, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dish.name,
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D428A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dish.description,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          if (dish.whereToFind != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.place_outlined,
                  size: isMobile ? 16 : 18,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dish.whereToFind!,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrinksPage(bool isMobile) {
    final drinks = _locationMetadata?.foodAndDrink?.signatureDrinks ?? [];
    final cultureNotes = _locationMetadata?.foodAndDrink?.foodCultureNotes ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drinks section
          if (drinks.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.local_bar,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Signature Drinks',
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...drinks.map((drink) => _buildDrinkCard(drink, isMobile)).toList(),
          ],

          // Culture notes section
          if (cultureNotes.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.auto_stories,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Food Culture',
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cultureNotes.map((note) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          color: const Color(0xFF1D428A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note,
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrinkCard(SignatureDrink drink, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            drink.name,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D428A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            drink.description,
            style: TextStyle(
              fontSize: isMobile ? 13 : 15,
              color: Colors.grey[700],
            ),
          ),
          if (drink.howLocalsDrinkIt != null) ...[
            const SizedBox(height: 8),
            Text(
              drink.howLocalsDrinkIt!,
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isMobile) {
    // Calculate total pages
    int totalPages = 1; // Fun fact is always there
    if (_locationMetadata?.visualElements != null) {
      if (_locationMetadata!.visualElements!.landmarks.isNotEmpty ||
          _locationMetadata!.visualElements!.uniqueModern.isNotEmpty) totalPages++;
    }
    if (_locationMetadata?.foodAndDrink != null) {
      if (_locationMetadata!.foodAndDrink!.heroDishes.isNotEmpty) totalPages++;
      if (_locationMetadata!.foodAndDrink!.signatureDrinks.isNotEmpty ||
          _locationMetadata!.foodAndDrink!.foodCultureNotes.isNotEmpty) totalPages++;
    }

    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (index) {
          final isActive = index == _discoveryCardPage;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  void _resetGame() {
    // Record the result of the just-finished game if not already recorded
    if (_challenge != null && _guesses.isNotEmpty) {
      // Check if this game is already in recent games (to avoid duplicates)
      final currentGameAlreadyRecorded = _recentGames.isNotEmpty &&
        _recentGames.last.locationName == _challenge!.name &&
        _recentGames.last.attempts == (6 - _attemptsLeft);

      if (!currentGameAlreadyRecorded) {
        final won = _lastDistance != null && _lastDistance! < _challenge!.winThresholdKm;
        _recordGameResult(won);
      }
    }

    // Get next challenge and update state
    _getNextChallenge().then((nextChallenge) {
      setState(() {
        _challenge = nextChallenge;

        _guesses.clear();
        _attemptsLeft = 6;
        _lastDistance = null;
        _feedback = "Tap the map to guess the location!";
        _hintUsed = false;
        _showRadiusHint = false;
        _guessHistoryExpanded = false;
        _showDiscoveryCard = false;
        _locationMetadata = null;
        _discoveryCardPage = 0;
        _mapController.move(_getRandomOffsetStart(), _challenge!.initialZoom);
      });
    });
    _clearState();
  }
}
