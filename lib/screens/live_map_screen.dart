import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/trip_manager.dart';
import '../data/trips.dart';

class LiveMapScreen extends StatefulWidget {
  final String busNumber;

  const LiveMapScreen({super.key, required this.busNumber});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  Timer? _refreshTimer;

  BusTrip? currentTrip;

  final MapController _mapController = MapController();

  bool _mapReady = false;

  @override
  void initState() {
    super.initState();

    _loadTrip();

    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;

      _loadTrip();
    });
  }

  // ------------------------------------------------------------
  // LOAD CURRENT TRIP
  // ------------------------------------------------------------

  void _loadTrip() {
    final trip = TripManager.getActiveTripByBusNumber(widget.busNumber);

    if (!mounted) return;

    setState(() {
      currentTrip = trip;
    });

    if (_mapReady &&
        trip != null &&
        trip.latitude != null &&
        trip.longitude != null) {
      _mapController.move(LatLng(trip.latitude!, trip.longitude!), 15);
    }
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final double? latitude = currentTrip?.latitude;
    final double? longitude = currentTrip?.longitude;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.busNumber} - Live Location'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: latitude != null && longitude != null
          ? Stack(
              children: [
                // ------------------------------------------------
                // MAP
                // ------------------------------------------------
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(latitude, longitude),
                    initialZoom: 15,
                    onMapReady: () {
                      _mapReady = true;

                      if (currentTrip != null &&
                          currentTrip!.latitude != null &&
                          currentTrip!.longitude != null) {
                        _mapController.move(
                          LatLng(
                            currentTrip!.latitude!,
                            currentTrip!.longitude!,
                          ),
                          15,
                        );
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.travel_buddy',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(latitude, longitude),
                          width: 70,
                          height: 70,
                          child: const Icon(
                            Icons.directions_bus,
                            size: 45,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // ------------------------------------------------
                // LIVE INFORMATION
                // ------------------------------------------------
                Positioned(
                  left: 15,
                  right: 15,
                  bottom: 15,
                  child: Card(
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 12,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Spacer(),
                              Text('Route ${currentTrip!.routeNo}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${currentTrip!.from} → '
                            '${currentTrip!.to}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Latitude: '
                            '${latitude.toStringAsFixed(6)}',
                          ),
                          Text(
                            'Longitude: '
                            '${longitude.toStringAsFixed(6)}',
                          ),
                          if (currentTrip!.accuracy != null)
                            Text(
                              'Accuracy: '
                              '${currentTrip!.accuracy!.toStringAsFixed(1)} m',
                            ),
                          const SizedBox(height: 5),
                          const Text(
                            'Location updates every 2 seconds',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 60, color: Colors.grey),
                  SizedBox(height: 15),
                  Text(
                    'Live GPS location is not available.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
    );
  }
}
