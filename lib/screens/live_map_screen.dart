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

  // When true, map automatically follows the bus.
  bool _followBus = true;

  @override
  void initState() {
    super.initState();

    _loadTrip();

    // Refresh bus GPS/status every 2 seconds.
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;

      _loadTrip();
    });
  }

  // ------------------------------------------------------------
  // LOAD CURRENT BUS TRIP
  // ------------------------------------------------------------
  void _loadTrip() {
    final BusTrip? trip = TripManager.getActiveTripByBusNumber(
      widget.busNumber,
    );

    if (!mounted) return;

    setState(() {
      currentTrip = trip;
    });

    // Follow bus only when follow mode is enabled.
    if (_followBus &&
        _mapReady &&
        trip != null &&
        trip.latitude != null &&
        trip.longitude != null) {
      _mapController.move(LatLng(trip.latitude!, trip.longitude!), 15);
    }
  }

  // ------------------------------------------------------------
  // CENTER MAP ON BUS
  // ------------------------------------------------------------
  void _centerOnBus() {
    final trip = currentTrip;

    if (trip == null || trip.latitude == null || trip.longitude == null) {
      return;
    }

    setState(() {
      _followBus = true;
    });

    if (_mapReady) {
      _mapController.move(LatLng(trip.latitude!, trip.longitude!), 15);
    }
  }

  // ------------------------------------------------------------
  // TOGGLE FOLLOW BUS
  // ------------------------------------------------------------
  void _toggleFollowBus() {
    setState(() {
      _followBus = !_followBus;
    });

    if (_followBus) {
      _centerOnBus();
    }
  }

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

    final bool hasLocation = latitude != null && longitude != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.busNumber} - Live Location'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,

        // Follow bus button
        actions: [
          IconButton(
            tooltip: _followBus ? 'Following bus' : 'Follow bus',
            onPressed: _toggleFollowBus,
            icon: Icon(_followBus ? Icons.gps_fixed : Icons.gps_not_fixed),
          ),
        ],
      ),

      body: hasLocation
          ? Stack(
              children: [
                // ==================================================
                // MAP
                // ==================================================
                FlutterMap(
                  mapController: _mapController,

                  options: MapOptions(
                    initialCenter: LatLng(latitude, longitude),
                    initialZoom: 15,

                    onMapReady: () {
                      _mapReady = true;

                      if (_followBus &&
                          currentTrip != null &&
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
                    // ==================================================
                    // OPEN STREET MAP
                    // ==================================================
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                      userAgentPackageName: 'com.example.travel_buddy',
                    ),

                    // ==================================================
                    // BUS MARKER
                    // ==================================================
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(latitude, longitude),

                          width: 120,
                          height: 100,

                          child: Column(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              // Bus number label
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),

                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),

                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),

                                child: Text(
                                  currentTrip?.busNumber ?? widget.busNumber,

                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 3),

                              // Bus icon
                              const Icon(
                                Icons.directions_bus,
                                size: 46,
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // ==================================================
                // FOLLOW / RECENTER BUTTON
                // ==================================================
                Positioned(
                  right: 16,
                  bottom: 205,

                  child: FloatingActionButton.small(
                    heroTag: 'centerBusButton',

                    onPressed: _centerOnBus,

                    tooltip: 'Center on bus',

                    child: Icon(
                      _followBus ? Icons.gps_fixed : Icons.my_location,
                    ),
                  ),
                ),

                // ==================================================
                // FOLLOW STATUS
                // ==================================================
                Positioned(
                  top: 15,
                  left: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),

                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 4,
                          offset: Offset(0, 2),
                          color: Colors.black26,
                        ),
                      ],
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        Icon(
                          _followBus ? Icons.gps_fixed : Icons.pan_tool,

                          size: 18,

                          color: _followBus ? Colors.green : Colors.orange,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          _followBus ? 'Following Bus' : 'Free Map',

                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ==================================================
                // BUS INFORMATION CARD
                // ==================================================
                Positioned(
                  left: 15,
                  right: 15,
                  bottom: 15,

                  child: SafeArea(
                    child: Card(
                      elevation: 6,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(15),

                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              // ------------------------------------
                              // LIVE STATUS
                              // ------------------------------------
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,

                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // ------------------------------------
                              // BUS NUMBER
                              // ------------------------------------
                              Text(
                                'Bus: ${currentTrip!.busNumber}',

                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 5),

                              // ------------------------------------
                              // ROUTE
                              // ------------------------------------
                              Text(
                                'Route ${currentTrip!.routeNo}',

                                style: const TextStyle(fontSize: 14),
                              ),

                              const SizedBox(height: 5),

                              // ------------------------------------
                              // CATEGORY
                              // ------------------------------------
                              Text(
                                currentTrip!.busCategory.isEmpty
                                    ? 'Category: Not specified'
                                    : 'Category: ${currentTrip!.busCategory}',

                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 7),

                              // ------------------------------------
                              // FROM -> TO
                              // ------------------------------------
                              Text(
                                '${currentTrip!.from} → ${currentTrip!.to}',

                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // ------------------------------------
                              // GPS ACCURACY
                              // ------------------------------------
                              Row(
                                children: [
                                  const Icon(
                                    Icons.gps_fixed,
                                    size: 18,
                                    color: Colors.blue,
                                  ),

                                  const SizedBox(width: 6),

                                  Text(
                                    currentTrip!.accuracy != null
                                        ? 'GPS Accuracy: '
                                              '${currentTrip!.accuracy!.toStringAsFixed(1)} m'
                                        : 'GPS Accuracy: Not available',

                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 5),

                              // ------------------------------------
                              // UPDATE INFORMATION
                              // ------------------------------------
                              const Text(
                                'Location updates automatically every 2 seconds.',

                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          // ========================================================
          // NO GPS LOCATION
          // ========================================================
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(25),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Icon(Icons.location_off, size: 65, color: Colors.grey),

                    SizedBox(height: 15),

                    Text(
                      'Live GPS location is not available.',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'Please wait for the bus GPS location to become available.',

                      textAlign: TextAlign.center,

                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
