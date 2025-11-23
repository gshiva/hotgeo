import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

class LocationChallenge {
  final String name;
  final LatLng coordinates;
  final double initialZoom;

  const LocationChallenge({
    required this.name,
    required this.coordinates,
    required this.initialZoom,
  });
}

class _GameScreenState extends State<GameScreen> {
  // Get daily location based on date (in debug mode, regenerates after each game)
  late LocationChallenge _challenge = _getDailyChallenge();
  final List<LatLng> _guesses = [];
  final MapController _mapController = MapController();
  int _attemptsLeft = 6;
  double? _lastDistance;
  String _feedback = "Tap the map to guess the location!";

  LocationChallenge _getDailyChallenge({int? customSeed}) {
    // Use date as seed for consistent daily challenge (or custom seed for testing)
    final int seed;
    if (customSeed != null) {
      seed = customSeed;
    } else {
      final today = DateTime.now();
      seed = today.year * 10000 + today.month * 100 + today.day;
    }
    final random = Random(seed);

    // Locations with zoom levels based on specificity (lower zoom = world view, higher zoom = regional view)
    // Note: Cities selected have English/Latin script labels on OpenStreetMap
    final challenges = [
      // Major cities - world view (you need to know which continent)
      const LocationChallenge(name: "Paris, France", coordinates: LatLng(48.8566, 2.3522), initialZoom: 2.5),
      const LocationChallenge(name: "New York, USA", coordinates: LatLng(40.7128, -74.0060), initialZoom: 2.5),
      const LocationChallenge(name: "Sydney, Australia", coordinates: LatLng(-33.8688, 151.2093), initialZoom: 2.5),
      const LocationChallenge(name: "London, UK", coordinates: LatLng(51.5074, -0.1278), initialZoom: 2.5),
      const LocationChallenge(name: "São Paulo, Brazil", coordinates: LatLng(-23.5505, -46.6333), initialZoom: 2.5),
      const LocationChallenge(name: "Mexico City, Mexico", coordinates: LatLng(19.4326, -99.1332), initialZoom: 2.5),
      const LocationChallenge(name: "Los Angeles, USA", coordinates: LatLng(34.0522, -118.2437), initialZoom: 2.5),
      const LocationChallenge(name: "Rome, Italy", coordinates: LatLng(41.9028, 12.4964), initialZoom: 2.5),
      const LocationChallenge(name: "Berlin, Germany", coordinates: LatLng(52.5200, 13.4050), initialZoom: 2.5),
      const LocationChallenge(name: "Buenos Aires, Argentina", coordinates: LatLng(-34.6037, -58.3816), initialZoom: 2.5),
      const LocationChallenge(name: "Dubai, UAE", coordinates: LatLng(25.2048, 55.2708), initialZoom: 2.5),
      const LocationChallenge(name: "Singapore", coordinates: LatLng(1.3521, 103.8198), initialZoom: 3),
      const LocationChallenge(name: "Ottawa, Canada", coordinates: LatLng(45.4215, -75.6972), initialZoom: 2.5),
      const LocationChallenge(name: "Melbourne, Australia", coordinates: LatLng(-37.8136, 144.9631), initialZoom: 2.5),
      const LocationChallenge(name: "Amsterdam, Netherlands", coordinates: LatLng(52.3676, 4.9041), initialZoom: 2.5),
      const LocationChallenge(name: "Barcelona, Spain", coordinates: LatLng(41.3851, 2.1734), initialZoom: 2.5),
      const LocationChallenge(name: "Istanbul, Turkey", coordinates: LatLng(41.0082, 28.9784), initialZoom: 2.5),
      const LocationChallenge(name: "Cape Town, South Africa", coordinates: LatLng(-33.9249, 18.4241), initialZoom: 2.5),
      const LocationChallenge(name: "Rio de Janeiro, Brazil", coordinates: LatLng(-22.9068, -43.1729), initialZoom: 2.5),
      const LocationChallenge(name: "Vienna, Austria", coordinates: LatLng(48.2082, 16.3738), initialZoom: 2.5),
    ];

    return challenges[random.nextInt(challenges.length)];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🗺️ HotGeo',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
              Text(
                'Attempts: $_attemptsLeft/6',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B4513).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8B4513), width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.place, color: Color(0xFF5D4037), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Find: ${_challenge.name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Container(
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
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _challenge.coordinates,
            initialZoom: _challenge.initialZoom,
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
            // Show target after game ends
            if (_attemptsLeft == 0 || (_lastDistance != null && _lastDistance! < 50))
              MarkerLayer(
                markers: [
                  Marker(
                    point: _challenge.coordinates,
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
          ],
        ),
      ),
    );
  }

  void _handleMapTap(TapPosition tapPos, LatLng point) {
    if (_attemptsLeft <= 0) return;
    if (_lastDistance != null && _lastDistance! < 50) return;

    setState(() {
      _guesses.add(point);
      _attemptsLeft--;
      _lastDistance = _calculateDistance(point, _challenge.coordinates);
      _feedback = _generateFeedback(_lastDistance!);

      if (_lastDistance! < 50) { // Within 50km = WIN!
        _feedback = "🎉 YOU FOUND IT!\nDistance: ${_lastDistance!.toStringAsFixed(0)}km";
      } else if (_attemptsLeft == 0) {
        _feedback = "💀 Game Over!\nThe location is now revealed on the map.";
      }
    });
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, p1, p2);
  }

  String _generateFeedback(double distance) {
    if (distance < 100) return "🔥 BURNING HOT!\nYou're very close!";
    if (distance < 500) return "🌡️ Very warm!\nKeep searching in this area.";
    if (distance < 1000) return "♨️ Getting warmer...\nYou're heading in the right direction.";
    if (distance < 2000) return "❄️ Cold...\nTry a different region.";
    return "🧊 Freezing cold!\nYou're very far away.";
  }

  Color _getMarkerColor(int index) {
    if (index >= _guesses.length) return Colors.grey;
    final distance = _calculateDistance(_guesses[index], _challenge.coordinates);
    if (distance < 100) return Colors.red;
    if (distance < 500) return Colors.orange;
    if (distance < 1000) return Colors.yellow;
    return Colors.blue;
  }

  String _generateShareText() {
    final attempts = 6 - _attemptsLeft;
    final won = _lastDistance != null && _lastDistance! < 50;
    final squares = _guesses.map((g) {
      final d = _calculateDistance(g, _challenge.coordinates);
      if (d < 100) return '🟥';
      if (d < 500) return '🟧';
      if (d < 1000) return '🟨';
      return '🟦';
    }).join();

    final today = DateTime.now();
    return 'HotGeo ${today.month}/${today.day}\n'
           'Attempts: $attempts/6\n'
           '$squares\n'
           '${won ? "🏆 Found it!" : "💀 Failed"}\n\n'
           'Play at: https://github.com/gshiva/hotgeo';
  }

  Widget _buildFeedbackPanel() {
    final gameEnded = _attemptsLeft == 0 || (_lastDistance != null && _lastDistance! < 50);

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
              color: const Color(0xFFE8D4B0),
              border: Border.all(color: const Color(0xFF8B4513), width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
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
              final dist = _calculateDistance(_guesses[index], _challenge.coordinates);
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
            if (kDebugMode)
              ElevatedButton.icon(
                onPressed: _resetGame,
                icon: const Icon(Icons.refresh),
                label: const Text('Play Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF8B4513), width: 2),
                ),
                child: const Text(
                  '📅 Come back tomorrow for a new location!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                final text = _generateShareText();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Score copied!\n\n$text'),
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Share Score'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8B4513),
                side: const BorderSide(color: Color(0xFF8B4513), width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      // In debug mode, get a new random challenge each time
      if (kDebugMode) {
        _challenge = _getDailyChallenge(customSeed: DateTime.now().millisecondsSinceEpoch);
      }

      _guesses.clear();
      _attemptsLeft = 6;
      _lastDistance = null;
      _feedback = "Tap the map to guess the location!";
      _mapController.move(_challenge.coordinates, _challenge.initialZoom);
    });
  }
}
