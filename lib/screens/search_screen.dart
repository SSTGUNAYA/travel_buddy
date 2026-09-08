import 'dart:async';

import 'package:flutter/material.dart';

import '../data/trips.dart';
import '../data/trip_manager.dart';
import 'bus_timetable_screen.dart';
import 'live_map_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    // Refresh screen every 2 seconds
    // so Live GPS / trip status can update.
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;

      setState(() {});
    });
  }

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
  // Bus Number + Route + From + To + Category
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
          trip.to.toLowerCase().contains(query) ||
          trip.busCategory.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    searchController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // OPEN LIVE MAP
  // ------------------------------------------------------------
  void openLiveMap(BusTrip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveMapScreen(busNumber: trip.busNumber),
      ),
    );
  }

  // ------------------------------------------------------------
  // OPEN BUS TIMETABLE
  // ------------------------------------------------------------
  void openTimetable(BusTrip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusTimetableScreen(routeNo: trip.routeNo),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final trips = filteredTrips;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Bus'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // ==================================================
            // SEARCH BOX
            // ==================================================
            TextField(
              controller: searchController,

              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },

              decoration: InputDecoration(
                hintText: 'Bus Number, Route or Destination',

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

            // ==================================================
            // BUS LIST
            // ==================================================
            Expanded(
              child: trips.isEmpty
                  ? _buildNoBusesMessage()
                  : ListView.builder(
                      itemCount: trips.length,

                      itemBuilder: (context, index) {
                        final trip = trips[index];

                        return _buildBusCard(trip);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // NO BUSES MESSAGE
  // ------------------------------------------------------------
  Widget _buildNoBusesMessage() {
    final bool isSearching = searchQuery.trim().isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.directions_bus_outlined,
            size: 70,
            color: Colors.grey,
          ),

          const SizedBox(height: 15),

          Text(
            isSearching ? 'No buses found' : 'No buses available',

            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            isSearching
                ? 'Try another bus number, route or destination.'
                : 'No scheduled or live buses are available.',
            textAlign: TextAlign.center,

            style: const TextStyle(fontSize: 15, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BUS CARD
  // ------------------------------------------------------------
  Widget _buildBusCard(BusTrip trip) {
    final bool isLive = trip.status == 'Live';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),

      elevation: 3,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      child: InkWell(
        borderRadius: BorderRadius.circular(14),

        onTap: () {
          if (isLive) {
            openLiveMap(trip);
          } else {
            openTimetable(trip);
          }
        },

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ==================================================
              // BUS HEADER
              // ==================================================
              Row(
                children: [
                  CircleAvatar(
                    radius: 27,

                    backgroundColor: isLive ? Colors.green : Colors.blue,

                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      trip.busNumber,

                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // STATUS
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: isLive
                          ? Colors.green.shade100
                          : Colors.orange.shade100,

                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Text(
                      isLive ? 'LIVE' : 'SCHEDULED',

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

              const SizedBox(height: 16),

              // ==================================================
              // ROUTE
              // ==================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Icon(Icons.alt_route, size: 21, color: Colors.blue),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Route ${trip.routeNo}',

                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 9),

              // ==================================================
              // BUS CATEGORY
              // ==================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Icon(Icons.category, size: 21, color: Colors.blue),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      trip.busCategory.isEmpty
                          ? 'Category: Not specified'
                          : 'Category: ${trip.busCategory}',

                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 9),

              // ==================================================
              // FROM → TO
              // ==================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Icon(Icons.route, size: 21, color: Colors.blue),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      '${trip.from} → ${trip.to}',

                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 9),

              // ==================================================
              // DEPARTURE TIME
              // ==================================================
              Row(
                children: [
                  const Icon(Icons.access_time, size: 21, color: Colors.blue),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Departure: ${trip.departureTime}',

                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              // ==================================================
              // LIVE GPS STATUS
              // ==================================================
              if (isLive) ...[
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),

                  decoration: BoxDecoration(
                    color: trip.latitude != null && trip.longitude != null
                        ? Colors.green.shade50
                        : Colors.grey.shade100,

                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: Row(
                    children: [
                      Icon(
                        trip.latitude != null && trip.longitude != null
                            ? Icons.location_on
                            : Icons.location_off,

                        size: 20,

                        color: trip.latitude != null && trip.longitude != null
                            ? Colors.green
                            : Colors.grey,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          trip.latitude != null && trip.longitude != null
                              ? 'Live Location Available'
                              : 'GPS Location Unavailable',

                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,

                            color:
                                trip.latitude != null && trip.longitude != null
                                ? Colors.green.shade800
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // ==================================================
              // ACTION
              // ==================================================
              SizedBox(
                width: double.infinity,

                child: ElevatedButton.icon(
                  onPressed: () {
                    if (isLive) {
                      openLiveMap(trip);
                    } else {
                      openTimetable(trip);
                    }
                  },

                  icon: Icon(isLive ? Icons.map : Icons.schedule),

                  label: Text(isLive ? 'View Live Map' : 'View Timetable'),

                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
