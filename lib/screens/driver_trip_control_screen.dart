import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/bus_routes.dart';
import '../data/trips.dart';
import '../data/trip_manager.dart';

class DriverTripControlScreen extends StatefulWidget {
  const DriverTripControlScreen({super.key});

  @override
  State<DriverTripControlScreen> createState() =>
      _DriverTripControlScreenState();
}

class _DriverTripControlScreenState extends State<DriverTripControlScreen> {
  // Currently selected route
  BusRoute selectedRoute = busRoutes.first;

  // From / To
  late String fromLocation;
  late String toLocation;

  // Date / Time
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 6, minute: 30);

  // Trip status
  String tripStatus = 'Scheduled';

  // Current trip
  BusTrip? currentTrip;

  // GPS information
  Position? currentPosition;
  bool gpsActive = false;

  static const String driverBusNumber = 'NB-1234';

  @override
  void initState() {
    super.initState();

    fromLocation = selectedRoute.from;
    toLocation = selectedRoute.to;

    // Restore existing active trip
    final existingTrip = TripManager.getActiveTripByBusNumber(driverBusNumber);

    if (existingTrip != null) {
      currentTrip = existingTrip;

      tripStatus = existingTrip.status;

      // Restore route
      final matchingRoute = busRoutes.cast<BusRoute?>().firstWhere(
        (route) => route?.routeNo == existingTrip.routeNo,
        orElse: () => null,
      );

      if (matchingRoute != null) {
        selectedRoute = matchingRoute;
      }

      fromLocation = existingTrip.from;
      toLocation = existingTrip.to;

      selectedDate = existingTrip.departureDate;
    }
  }

  void _changeRoute(BusRoute? route) {
    if (route == null) return;

    setState(() {
      selectedRoute = route;
      fromLocation = route.from;
      toLocation = route.to;
      tripStatus = 'Scheduled';

      currentTrip = null;

      currentPosition = null;
      gpsActive = false;
    });
  }

  // ------------------------------------------------------------
  // SWITCH FROM / TO
  // ------------------------------------------------------------

  void _switchRoute() {
    if (tripStatus == 'Live') return;

    setState(() {
      final temp = fromLocation;
      fromLocation = toLocation;
      toLocation = temp;
    });
  }

  // ------------------------------------------------------------
  // GET TRIP STOPS
  // ------------------------------------------------------------

  List<String> getTripStops() {
    final stops = selectedRoute.stops;

    final fromIndex = stops.indexOf(fromLocation);
    final toIndex = stops.indexOf(toLocation);

    if (fromIndex == -1 || toIndex == -1) {
      return [];
    }

    if (fromIndex <= toIndex) {
      return stops.sublist(fromIndex, toIndex + 1);
    }

    return stops.sublist(toIndex, fromIndex + 1).reversed.toList();
  }

  // ------------------------------------------------------------
  // SELECT DATE
  // ------------------------------------------------------------

  Future<void> _selectDate() async {
    if (tripStatus == 'Live') return;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  // ------------------------------------------------------------
  // SELECT TIME
  // ------------------------------------------------------------

  Future<void> _selectTime() async {
    if (tripStatus == 'Live') return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
        tripStatus = 'Scheduled';
      });
    }
  }

  // ------------------------------------------------------------
  // SAVE SCHEDULE
  // ------------------------------------------------------------

  void _saveSchedule() {
    if (tripStatus == 'Live') return;

    // ------------------------------------------------------------
    // UPDATE EXISTING TRIP
    // ------------------------------------------------------------
    if (currentTrip != null) {
      final updatedTrip = BusTrip(
        tripId: currentTrip!.tripId,
        routeNo: selectedRoute.routeNo,
        busNumber: driverBusNumber,
        from: fromLocation,
        to: toLocation,
        stops: getTripStops(),
        departureDate: selectedDate,
        departureTime: selectedTime.format(context),
        status: 'Scheduled',
      );

      setState(() {
        currentTrip = updatedTrip;
        tripStatus = 'Scheduled';

        currentPosition = null;
        gpsActive = false;
      });

      TripManager.updateTrip(updatedTrip);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip updated successfully.')),
      );

      return;
    }

    // ------------------------------------------------------------
    // CREATE NEW TRIP
    // ------------------------------------------------------------
    final newTrip = BusTrip(
      tripId: DateTime.now().millisecondsSinceEpoch.toString(),
      routeNo: selectedRoute.routeNo,
      busNumber: driverBusNumber,
      from: fromLocation,
      to: toLocation,
      stops: getTripStops(),
      departureDate: selectedDate,
      departureTime: selectedTime.format(context),
      status: 'Scheduled',
    );

    setState(() {
      currentTrip = newTrip;
      tripStatus = 'Scheduled';

      currentPosition = null;
      gpsActive = false;
    });

    TripManager.addTrip(newTrip);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip schedule saved successfully.')),
    );
  }

  Future<Position?> _getCurrentLocation() async {
    // Check whether GPS / location service is enabled
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please turn on GPS / Location service.'),
          ),
        );
      }

      return null;
    }

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();

    // Request permission if not granted
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }

        return null;
      }
    }

    // Permanently denied
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is permanently denied. '
              'Please enable it from Settings.',
            ),
          ),
        );
      }

      return null;
    }

    // Get current position
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return position;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to get GPS location: $e')),
        );
      }

      return null;
    }
  }

  // ------------------------------------------------------------
  // START TRIP
  // ------------------------------------------------------------

  Future<void> _startTrip() async {
    if (currentTrip == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please save the trip schedule first.')),
      );

      return;
    }

    // Get GPS location first
    final Position? position = await _getCurrentLocation();

    //IMPORTANT:
    //Check whether this screen is still mounted:
    //after the async operation.
    if (!mounted) return;

    if (position == null) {
      return;
    }

    // Start trip
    setState(() {
      currentPosition = position;
      gpsActive = true;

      currentTrip!.status = 'Live';
      tripStatus = 'Live';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip started successfully. GPS is active.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ------------------------------------------------------------
  // COMPLETE TRIP
  // ------------------------------------------------------------

  void _completeTrip() {
    if (tripStatus != 'Live' || currentTrip == null) {
      return;
    }

    final completedTrip = BusTrip(
      tripId: currentTrip!.tripId,
      routeNo: currentTrip!.routeNo,
      busNumber: currentTrip!.busNumber,
      from: currentTrip!.from,
      to: currentTrip!.to,
      stops: currentTrip!.stops,
      departureDate: currentTrip!.departureDate,
      departureTime: currentTrip!.departureTime,
      status: 'Completed',
    );

    TripManager.updateTrip(completedTrip);

    setState(() {
      currentTrip = completedTrip;
      tripStatus = 'Completed';

      gpsActive = false;
      currentPosition = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Trip completed')));
  }

  // ------------------------------------------------------------
  // FORMAT DATE
  // ------------------------------------------------------------

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Trip Control'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // --------------------------------------------------
            // BUS INFORMATION
            // --------------------------------------------------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Bus Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Bus Number: NB-1234',
                      style: TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Route No: ${selectedRoute.routeNo}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // SELECT ROUTE
            // --------------------------------------------------
            const Text(
              'Select Route',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<BusRoute>(
              initialValue: selectedRoute,

              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.route),
              ),

              items: busRoutes
                  .map(
                    (route) => DropdownMenuItem<BusRoute>(
                      value: route,
                      child: Text(
                        '${route.routeNo} - '
                        '${route.from} → '
                        '${route.to}',
                      ),
                    ),
                  )
                  .toList(),

              onChanged: tripStatus == 'Live' ? null : _changeRoute,
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // FROM
            // --------------------------------------------------
            const Text(
              'From',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: fromLocation,

              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.trip_origin),
              ),

              items: selectedRoute.stops
                  .map(
                    (stop) => DropdownMenuItem<String>(
                      value: stop,
                      child: Text(stop),
                    ),
                  )
                  .toList(),

              onChanged: tripStatus == 'Live'
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        fromLocation = value;
                      });
                    },
            ),

            const SizedBox(height: 10),

            // --------------------------------------------------
            // SWITCH BUTTON
            // --------------------------------------------------
            Center(
              child: IconButton(
                onPressed: tripStatus == 'Live' ? null : _switchRoute,

                icon: const Icon(Icons.swap_vert, size: 35),

                tooltip: 'Switch From and To',
              ),
            ),

            // --------------------------------------------------
            // TO
            // --------------------------------------------------
            const Text(
              'To',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: toLocation,

              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),

              items: selectedRoute.stops
                  .map(
                    (stop) => DropdownMenuItem<String>(
                      value: stop,
                      child: Text(stop),
                    ),
                  )
                  .toList(),

              onChanged: tripStatus == 'Live'
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        toLocation = value;
                      });
                    },
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // DATE
            // --------------------------------------------------
            const Text(
              'Departure Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: tripStatus == 'Live' ? null : _selectDate,

                icon: const Icon(Icons.calendar_month),

                label: Text(_formatDate(selectedDate)),
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // TIME
            // --------------------------------------------------
            const Text(
              'Scheduled Departure Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: tripStatus == 'Live' ? null : _selectTime,

                icon: const Icon(Icons.access_time),

                label: Text(selectedTime.format(context)),
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // TRIP SUMMARY
            // --------------------------------------------------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Trip Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      '$fromLocation → '
                      '$toLocation',
                      style: const TextStyle(fontSize: 18),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Stops',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      getTripStops().join(' → '),
                      style: const TextStyle(fontSize: 15),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Estimated time: '
                      '${selectedRoute.estimatedTime}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // STATUS
            // --------------------------------------------------
            Card(
              child: ListTile(
                leading: Icon(
                  tripStatus == 'Live'
                      ? Icons.location_on
                      : tripStatus == 'Completed'
                      ? Icons.check_circle
                      : Icons.schedule,

                  color: tripStatus == 'Live'
                      ? Colors.green
                      : tripStatus == 'Completed'
                      ? Colors.grey
                      : Colors.orange,
                ),

                title: const Text(
                  'Trip Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: Text(tripStatus),
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // SAVE
            // --------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton.icon(
                onPressed: tripStatus == 'Live' ? null : _saveSchedule,

                icon: const Icon(Icons.save),

                label: const Text(
                  'SAVE / UPDATE TRIP',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // --------------------------------------------------
            // START TRIP
            // --------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: tripStatus == 'Scheduled' ? _startTrip : null,

                icon: const Icon(Icons.play_arrow),

                label: const Text(
                  'START TRIP',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // --------------------------------------------------
            // COMPLETE TRIP
            // --------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 50,

              child: OutlinedButton.icon(
                onPressed: tripStatus == 'Live' ? _completeTrip : null,

                icon: const Icon(Icons.stop),

                label: const Text('COMPLETE TRIP'),
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // LIVE LOCATION
            // --------------------------------------------------
            if (tripStatus == 'Live')
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          const Icon(Icons.gps_fixed, color: Colors.green),

                          const SizedBox(width: 8),

                          const Text(
                            'Live Location',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const Spacer(),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: const Text(
                              'GPS ACTIVE',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      if (currentPosition != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.my_location, size: 20),

                            const SizedBox(width: 8),

                            const Text(
                              'Latitude:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                currentPosition!.latitude.toStringAsFixed(6),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 20),

                            const SizedBox(width: 8),

                            const Text(
                              'Longitude:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                currentPosition!.longitude.toStringAsFixed(6),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Icon(Icons.gps_fixed, size: 20),

                            const SizedBox(width: 8),

                            const Text(
                              'Accuracy:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(width: 8),

                            Text(
                              '${currentPosition!.accuracy.toStringAsFixed(1)} m',
                            ),
                          ],
                        ),
                      ] else
                        const Text('Waiting for GPS location...'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
