import 'package:flutter/material.dart';
import '../data/trips.dart';
import '../data/trip_manager.dart';

class BusTimetableScreen extends StatefulWidget {
  const BusTimetableScreen({super.key});

  @override
  State<BusTimetableScreen> createState() => _BusTimetableScreenState();
}

class _BusTimetableScreenState extends State<BusTimetableScreen> {
  String searchText = '';

  List<BusTrip> get filteredTrips {
    final trips = TripManager.getAllTrips();

    if (searchText.trim().isEmpty) {
      return trips;
    }

    final query = searchText.toLowerCase();

    return trips.where((trip) {
      return trip.routeNo.toLowerCase().contains(query) ||
          trip.busNumber.toLowerCase().contains(query) ||
          trip.from.toLowerCase().contains(query) ||
          trip.to.toLowerCase().contains(query);
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Live':
        return Colors.green;
      case 'Completed':
        return Colors.grey;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Live':
        return Icons.location_on;
      case 'Completed':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final trips = filteredTrips;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Timetable'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          // SEARCH
          Padding(
            padding: const EdgeInsets.all(16),

            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },

              decoration: InputDecoration(
                hintText: 'Search bus, route or destination',

                prefixIcon: const Icon(Icons.search),

                border: const OutlineInputBorder(),

                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            searchText = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
            ),
          ),

          // TRIP LIST
          Expanded(
            child: trips.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Icon(Icons.directions_bus_outlined, size: 70),

                        SizedBox(height: 15),

                        Text(
                          'No buses available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text('Try another route or destination.'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),

                    itemCount: trips.length,

                    itemBuilder: (context, index) {
                      final trip = trips[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),

                        child: Padding(
                          padding: const EdgeInsets.all(16),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              // ROUTE
                              Row(
                                children: [
                                  CircleAvatar(
                                    child: Text(
                                      trip.routeNo,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Text(
                                      '${trip.from} → '
                                      '${trip.to}',

                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 15),

                              // TIME
                              Row(
                                children: [
                                  const Icon(Icons.access_time),

                                  const SizedBox(width: 8),

                                  Text(
                                    trip.departureTime,

                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // BUS NUMBER
                              Row(
                                children: [
                                  const Icon(Icons.directions_bus),

                                  const SizedBox(width: 8),

                                  Text(trip.busNumber),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // STATUS
                              Row(
                                children: [
                                  Icon(
                                    _statusIcon(trip.status),

                                    color: _statusColor(trip.status),
                                  ),

                                  const SizedBox(width: 8),

                                  Text(
                                    trip.status,

                                    style: TextStyle(
                                      color: _statusColor(trip.status),

                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // STOPS
                              Text(
                                'Stops: '
                                '${trip.stops.join(' → ')}',

                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
