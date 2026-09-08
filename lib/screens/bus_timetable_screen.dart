import 'package:flutter/material.dart';
import '../data/trips.dart';
import '../data/trip_manager.dart';

class BusTimetableScreen extends StatefulWidget {
  final String? routeNo;

  const BusTimetableScreen({super.key, this.routeNo});

  @override
  State<BusTimetableScreen> createState() => _BusTimetableScreenState();
}

class _BusTimetableScreenState extends State<BusTimetableScreen> {
  String searchText = '';

  DateTime? getDepartureDateTime(BusTrip trip) {
    final timeParts = trip.departureTime.split(':');

    if (timeParts.length < 2) {
      return null;
    }

    int hour = int.tryParse(timeParts[0]) ?? 0;
    int minute = int.tryParse(timeParts[1]) ?? 0;

    // Handle AM / PM if departureTime contains it
    final timeText = trip.departureTime.toLowerCase();

    if (timeText.contains('pm') && hour < 12) {
      hour += 12;
    }

    if (timeText.contains('am') && hour == 12) {
      hour = 0;
    }

    return DateTime(
      trip.departureDate.year,
      trip.departureDate.month,
      trip.departureDate.day,
      hour,
      minute,
    );
  }

  List<BusTrip> get filteredTrips {
    final trips = TripManager.getAllTrips();

    final query = searchText.trim().toLowerCase();

    final filtered = trips.where((trip) {
      final matchesRoute =
          widget.routeNo == null || trip.routeNo == widget.routeNo;

      final matchesSearch =
          query.isEmpty ||
          trip.routeNo.toLowerCase().contains(query) ||
          trip.busNumber.toLowerCase().contains(query) ||
          trip.from.toLowerCase().contains(query) ||
          trip.to.toLowerCase().contains(query);

      return matchesRoute && matchesSearch;
    }).toList();

    // Sort by departure date and time
    filtered.sort((a, b) {
      final dateA = getDepartureDateTime(a);
      final dateB = getDepartureDateTime(b);

      if (dateA == null || dateB == null) {
        return 0;
      }

      return dateA.compareTo(dateB);
    });

    return filtered;
  }

  Color getStatusColor(String status) {
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

  bool isNextBus(BusTrip trip, List<BusTrip> trips) {
    final now = DateTime.now();
    final departure = getDepartureDateTime(trip);

    if (departure == null) {
      return false;
    }

    // Only consider future trips
    final futureTrips = trips.where((item) {
      final itemDeparture = getDepartureDateTime(item);

      if (itemDeparture == null) {
        return false;
      }

      return itemDeparture.isAfter(now) &&
          item.status != 'Completed' &&
          item.status != 'Cancelled';
    }).toList();

    if (futureTrips.isEmpty) {
      return false;
    }

    futureTrips.sort((a, b) {
      final dateA = getDepartureDateTime(a)!;
      final dateB = getDepartureDateTime(b)!;

      return dateA.compareTo(dateB);
    });

    return futureTrips.first.tripId == trip.tripId;
  }

  IconData getStatusIcon(String status) {
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
          // SEARCH BOX
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

                border: const OutlineInputBorder(),
              ),
            ),
          ),

          // TIMETABLE
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

                        Text(
                          'No scheduled trips '
                          'found.',
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),

                    itemCount: trips.length,

                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      final nextBus = isNextBus(trip, trips);
                      final isLive = trip.status == 'Live';

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
                                      isLive
                                          ? '🟢 LIVE NOW\n${trip.from} → ${trip.to}'
                                          : nextBus
                                          ? '⭐ NEXT BUS\n${trip.from} → ${trip.to}'
                                          : '${trip.from} → ${trip.to}',

                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 15),

                              // DEPARTURE DATE
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today),

                                  const SizedBox(width: 8),

                                  Text(
                                    '${trip.departureDate.day.toString().padLeft(2, '0')}/'
                                    '${trip.departureDate.month.toString().padLeft(2, '0')}/'
                                    '${trip.departureDate.year}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // DEPARTURE TIME
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

                              const SizedBox(height: 15),

                              // BUS NUMBER
                              Row(
                                children: [
                                  const Icon(Icons.directions_bus),

                                  const SizedBox(width: 8),

                                  Expanded(
                                    child: Text(
                                      trip.busNumber,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // BUS CATEGORY
                              Row(
                                children: [
                                  const Icon(Icons.category),

                                  const SizedBox(width: 8),

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

                              const SizedBox(height: 8),
                              // STATUS
                              Row(
                                children: [
                                  Icon(
                                    getStatusIcon(trip.status),
                                    color: getStatusColor(trip.status),
                                  ),

                                  const SizedBox(width: 8),

                                  Text(
                                    trip.status,
                                    style: TextStyle(
                                      color: getStatusColor(trip.status),
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
