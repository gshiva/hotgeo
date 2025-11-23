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
  // Get daily location based on date
  late final LatLng _targetLocation = _getDailyLocation();
  final List<LatLng> _guesses = [];
  final MapController _mapController = MapController();
  int _attemptsLeft = 6;
  double? _lastDistance;
  String _feedback = "Tap the map to guess the location!";

  LatLng _getDailyLocation() {
    // Use date as seed for consistent daily challenge
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final random = Random(seed);

    // 20 interesting world cities
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
      child: Row(
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
            initialCenter: const LatLng(40, 0), // World view
            initialZoom: 2,
            onTap: _handleMapTap,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                    point: _targetLocation,
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
      _lastDistance = _calculateDistance(point, _targetLocation);
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
    final distance = _calculateDistance(_guesses[index], _targetLocation);
    if (distance < 100) return Colors.red;
    if (distance < 500) return Colors.orange;
    if (distance < 1000) return Colors.yellow;
    return Colors.blue;
  }

  String _generateShareText() {
    final attempts = 6 - _attemptsLeft;
    final won = _lastDistance != null && _lastDistance! < 50;
    final squares = _guesses.map((g) {
      final d = _calculateDistance(g, _targetLocation);
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
              final dist = _calculateDistance(_guesses[index], _targetLocation);
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
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      _guesses.clear();
      _attemptsLeft = 6;
      _lastDistance = null;
      _feedback = "Tap the map to guess the location!";
      _mapController.move(const LatLng(40, 0), 2);
    });
  }
}
