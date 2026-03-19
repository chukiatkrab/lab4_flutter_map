import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  LatLng _currentPosition = const LatLng(13.7563, 100.5018);
  bool _isLoading = true;

  double _accuracy = 50;
  String _mapStyle = "normal";

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _accuracy = position.accuracy;
        _isLoading = false;
      });

      _mapController.move(_currentPosition, 15.0);
    } catch (e) {
      print("ERROR: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 4 - Flutter Map'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition,
                initialZoom: 13,
              ),
              children: [
                // 🌍 MAP LAYER
                TileLayer(
                  urlTemplate: _mapStyle == "normal"
                      ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                      : 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                ),

                // 🔴 CIRCLE (โจทย์หลัก)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _currentPosition,
                      radius: _accuracy,
                      color: Colors.blue.withOpacity(0.3),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

                // 📍 MARKER
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_on,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),

      // 🔘 BUTTONS
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 📍 ปุ่มหาตำแหน่ง
          FloatingActionButton(
            onPressed: _determinePosition,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),

          // 🔄 เปลี่ยน map
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _mapStyle = _mapStyle == "normal" ? "topo" : "normal";
              });
            },
            child: const Icon(Icons.map),
          ),
        ],
      ),
    );
  }
}