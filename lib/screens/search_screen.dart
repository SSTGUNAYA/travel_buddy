import 'package:flutter/material.dart';

import '../data/bus_routes.dart';
import '../data/trips.dart';
import '../data/trip_manager.dart';
import 'bus_timetable_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();

  // Search text
  String searchQuery = '';

  // ------------------------------------------------------------
  // GET ACTIVE DRIVER TRIPS
  // Scheduled + Live only
  // ------------------------------------------------------------
  List<BusTrip> get activeTrips {
    return TripManager.getAllTrips()
        .where((trip) => trip.status == 'Scheduled' || trip.status == 'Live')
        .toList();
  }

  // ------------------------------------------------------------
  // FILTER DRIVER TRIPS
  // ------------------------------------------------------------
  List<BusTrip> get filteredTrips {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return activeTrips;
    }

    return activeTrips.where((trip) {
      return trip.busNumber.toLowerCase().contains(query) ||
          trip.routeNo.toLowerCase().contains(query) ||
          trip.from.toLowerCase().contains(query) ||
          trip.to.toLowerCase().contains(query);
    }).toList();
  }

  // ------------------------------------------------------------
  // FILTER STATIC ROUTES
  // ------------------------------------------------------------
  List<BusRoute> get filteredRoutes {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return busRoutes;
    }

    return busRoutes.where((route) {
      return route.routeNo.toLowerCase().contains(query) ||
          route.from.toLowerCase().contains(query) ||
          route.to.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final trips = filteredTrips;
    final routes = filteredRoutes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Bus'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // --------------------------------------------------
            // SEARCH BOX
            // --------------------------------------------------
            TextField(
              controller: searchController,

              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },

              decoration: InputDecoration(
                hintText: 'Enter Bus Number or Route',
                prefixIcon: const Icon(Icons.search),

                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();

                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : null,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [
                  // ==================================================
                  // DRIVER TRIPS
                  // ==================================================
                  if (trips.isNotEmpty) ...[
                    const Text(
                      'Available Buses',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    ...trips.map((trip) {
                      final bool isLive = trip.status == 'Live';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),

                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),

                          leading: CircleAvatar(
                            radius: 25,

                            backgroundColor: isLive
                                ? Colors.green
                                : Colors.blue,

                            child: const Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                            ),
                          ),

                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  trip.busNumber,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              // LIVE / SCHEDULED
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),

                                decoration: BoxDecoration(
                                  color: isLive
                                      ? Colors.green.shade100
                                      : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),

                                child: Text(
                                  trip.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isLive
                                        ? Colors.green.shade800
                                        : Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Route ${trip.routeNo}'),

                                const SizedBox(height: 4),

                                Text('${trip.from} → ${trip.to}'),

                                const SizedBox(height: 4),

                                Text('Departure: ${trip.departureTime}'),

                                // ------------------------------------------------
                                // LIVE GPS INFORMATION
                                // ------------------------------------------------
                                if (isLive &&
                                    trip.latitude != null &&
                                    trip.longitude != null) ...[
                                  const SizedBox(height: 8),

                                  const Text(
                                    'Live GPS Location',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    'Latitude: ${trip.latitude!.toStringAsFixed(6)}',
                                  ),

                                  Text(
                                    'Longitude: ${trip.longitude!.toStringAsFixed(6)}',
                                  ),

                                  if (trip.accuracy != null)
                                    Text(
                                      'Accuracy: '
                                      '${trip.accuracy!.toStringAsFixed(1)} m',
                                    ),
                                ],

                                // ------------------------------------------------
                                // GPS NOT AVAILABLE
                                // ------------------------------------------------
                                if (isLive &&
                                    (trip.latitude == null ||
                                        trip.longitude == null))
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                      'GPS location unavailable',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BusTimetableScreen(routeNo: trip.routeNo),
                              ),
                            );
                          },
                        ),
                      );
                    }),

                    const SizedBox(height: 20),
                  ],

                  // ==================================================
                  // ROUTES
                  // ==================================================
                  const Text(
                    'Routes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  if (routes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No routes found.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                  ...routes.map((route) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),

                      child: ListTile(
                        leading: const Icon(Icons.directions_bus),

                        title: Text(
                          '${route.routeNo} - '
                          '${route.from} → '
                          '${route.to}',
                        ),

                        subtitle: Text(
                          'Estimated Time: '
                          '${route.estimatedTime}',
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BusTimetableScreen(routeNo: route.routeNo),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
