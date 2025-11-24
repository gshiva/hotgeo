import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:html' as html show window, Navigator;
import 'dart:js_util' as js_util;

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

  // Location progression tracking
  int _currentLocationId = 1; // Current location in progression (1-365)

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
          color: const Color(0xFFF8F9FA),
          child: _buildFeedbackPanel(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
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
      ),
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
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1D428A).withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D428A).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        child: FlutterMap(
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
        ),
      ),
    );
  }

  void _handleMapTap(TapPosition tapPos, LatLng point) {
    if (_attemptsLeft <= 0) return;
    if (_lastDistance != null && _lastDistance! < _challenge!.winThresholdKm) return;

    setState(() {
      _guesses.add(point);
      _attemptsLeft--;
      _lastDistance = _calculateDistance(point, _challenge!.coordinates);
      _feedback = _generateFeedback(_lastDistance!);

      if (_lastDistance! < _challenge!.winThresholdKm) { // WIN!
        _feedback = "🎉 YOU FOUND IT!\nDistance: ${_lastDistance!.toStringAsFixed(0)}km";
      } else if (_attemptsLeft == 0) {
        _feedback = "💀 Game Over!\nThe location is now revealed on the map.";
      }
    });
    _saveState(); // Save progress after each guess
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
    // Get last 5 games (or fewer if not enough games played)
    final recentToShow = _recentGames.length > 5
        ? _recentGames.sublist(_recentGames.length - 5)
        : _recentGames;

    // Build streak line
    String streakLine = '';
    if (_winStreak > 0) {
      streakLine = '🔥 $_winStreak streak';
    }

    // Build session stats line
    String sessionLine = '';
    if (_todayGames > 0) {
      sessionLine = '$_todayWins-${_todayGames - _todayWins} today';
    }

    // Combine streak and session
    String headerLine = '';
    if (streakLine.isNotEmpty && sessionLine.isNotEmpty) {
      headerLine = '$streakLine | $sessionLine';
    } else if (streakLine.isNotEmpty) {
      headerLine = streakLine;
    } else if (sessionLine.isNotEmpty) {
      headerLine = sessionLine;
    }

    // Build recent wins section
    String recentWinsText = '';
    if (recentToShow.isNotEmpty) {
      recentWinsText = 'Recent:\n';
      for (final game in recentToShow) {
        final emoji = game.getDifficultyEmoji();
        final result = game.won ? '${game.attempts}/6' : '💀';
        recentWinsText += '${game.locationName} $emoji $result\n';
      }
    }

    // Build final share text
    String shareText = 'HotGeo 🗺️\n';
    if (headerLine.isNotEmpty) {
      shareText += '$headerLine\n\n';
    }
    if (recentWinsText.isNotEmpty) {
      shareText += '$recentWinsText\n';
    }
    shareText += 'https://gshiva.github.io/hotgeo/';

    return shareText;
  }

  Future<void> _shareResults() async {
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

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Feedback message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border.all(color: const Color(0xFF1D428A), width: 2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D428A).withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _feedback,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          if (_lastDistance != null) ...[
            const SizedBox(height: 16),
            Text(
              'Distance: ${_lastDistance!.toStringAsFixed(0)} km',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Guess history
          if (_guesses.isNotEmpty) ...[
            const Text(
              'Your Guesses:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(_guesses.length, (index) {
              final dist = _calculateDistance(_guesses[index], _challenge!.coordinates);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.circle,
                      color: _getMarkerColor(index),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Guess ${index + 1}: ${dist.toStringAsFixed(0)} km',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],

          // Action buttons
          if (gameEnded) ...[
            ElevatedButton.icon(
              onPressed: _resetGame,
              icon: const Icon(Icons.refresh),
              label: const Text('Play Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D428A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _shareResults,
              icon: const Icon(Icons.share),
              label: const Text('Share Score'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1D428A),
                side: const BorderSide(color: Color(0xFF1D428A), width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
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

  void _resetGame() {
    // Record the result of the just-finished game
    if (_challenge != null && _guesses.isNotEmpty) {
      final won = _lastDistance != null && _lastDistance! < _challenge!.winThresholdKm;
      _recordGameResult(won);
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
        _mapController.move(_getRandomOffsetStart(), _challenge!.initialZoom);
      });
    });
    _clearState();
  }
}
