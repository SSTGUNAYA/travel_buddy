import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/trips.dart';
import '../data/trip_manager.dart';

class DriverTripControlScreen extends StatefulWidget {
  final String busNumber;

  const DriverTripControlScreen({super.key, required this.busNumber});

  @override
  State<DriverTripControlScreen> createState() =>
      _DriverTripControlScreenState();
}

class _DriverTripControlScreenState extends State<DriverTripControlScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // BUS DATA FROM FIRESTORE
  // ============================================================

  String routeNumber = '';
  String fromLocation = '';
  String toLocation = '';

  bool isLoadingBus = true;

  // ============================================================
  // TRIP DATA
  // ============================================================

  DateTime selectedDate = DateTime.now();

  TimeOfDay selectedTime = const TimeOfDay(hour: 6, minute: 30);

  String tripStatus = 'Scheduled';

  BusTrip? currentTrip;

  // ============================================================
  // GPS
  // ============================================================

  Position? currentPosition;

  bool gpsActive = false;

  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();

    _loadBusData();
  }

  // ============================================================
  // LOAD BUS DATA FROM FIRESTORE
  // ============================================================

  Future<void> _loadBusData() async {
    try {
      final busId = widget.busNumber.trim().toUpperCase().replaceAll(
        RegExp(r'[^A-Z0-9]+'),
        '_',
      );

      final document = await _firestore.collection('buses').doc(busId).get();

      if (!mounted) return;

      if (!document.exists) {
        setState(() {
          isLoadingBus = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bus information was not found.'),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      final data = document.data();

      if (data == null) {
        setState(() {
          isLoadingBus = false;
        });
        return;
      }

      setState(() {
        routeNumber = data['routeNumber']?.toString() ?? '';
        fromLocation = data['from']?.toString() ?? '';
        toLocation = data['to']?.toString() ?? '';
        isLoadingBus = false;
      });

      final existingTrip = TripManager.getActiveTripByBusNumber(
        widget.busNumber,
      );

      if (existingTrip != null && mounted) {
        final parsedTime = _parseTime(existingTrip.departureTime);

        setState(() {
          currentTrip = existingTrip;
          tripStatus = existingTrip.status;
          selectedDate = existingTrip.departureDate;
          fromLocation = existingTrip.from;
          toLocation = existingTrip.to;

          if (parsedTime != null) {
            selectedTime = parsedTime;
          }

          gpsActive = existingTrip.status == 'Live';
        });

        if (existingTrip.status == 'Live') {
          _startLocationTracking();
        }
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingBus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load bus: ${e.message ?? e.code}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingBus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading bus: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // ============================================================
  // DATE
  // ============================================================

  Future<void> _selectDate() async {
    if (tripStatus == 'Live') {
      return;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (!mounted) return;

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  // ============================================================
  // TIME
  // ============================================================

  Future<void> _selectTime() async {
    if (tripStatus == 'Live') {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (!mounted) return;

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  // ============================================================
  // SAVE / UPDATE TRIP
  // ============================================================

  void _saveTrip() {
    if (tripStatus == 'Live') {
      return;
    }

    final from = fromLocation.trim();

    final to = toLocation.trim();

    final route = routeNumber.trim();

    if (route.isEmpty || from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route, From and To are required.'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (from.toLowerCase() == to.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('From and To cannot be the same.'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final departureTime = selectedTime.format(context);

    // ==========================================================
    // UPDATE EXISTING TRIP
    // ==========================================================

    if (currentTrip != null) {
      final updatedTrip = BusTrip(
        tripId: currentTrip!.tripId,
        routeNo: route,
        busNumber: widget.busNumber,
        from: from,
        to: to,
        stops: [from, to],
        departureDate: selectedDate,
        departureTime: departureTime,
        status: 'Scheduled',
        latitude: currentTrip!.latitude,
        longitude: currentTrip!.longitude,
        accuracy: currentTrip!.accuracy,
      );

      TripManager.updateTrip(updatedTrip);

      if (!mounted) return;

      setState(() {
        currentTrip = updatedTrip;

        tripStatus = 'Scheduled';

        currentPosition = null;

        gpsActive = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      return;
    }

    // ==========================================================
    // CREATE NEW TRIP
    // ==========================================================

    final newTrip = BusTrip(
      tripId: DateTime.now().millisecondsSinceEpoch.toString(),

      routeNo: route,

      busNumber: widget.busNumber,

      from: from,

      to: to,

      stops: [from, to],

      departureDate: selectedDate,

      departureTime: departureTime,

      status: 'Scheduled',
    );

    TripManager.addTrip(newTrip);

    if (!mounted) return;

    setState(() {
      currentTrip = newTrip;

      tripStatus = 'Scheduled';

      currentPosition = null;

      gpsActive = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip saved successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ============================================================
  // DELETE TRIP
  // ============================================================

  Future<void> _deleteTrip() async {
    if (currentTrip == null) {
      return;
    }

    if (tripStatus == 'Live') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stop the trip before deleting it.'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Trip?'),
          content: const Text('Are you sure you want to delete this trip?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final tripId = currentTrip!.tripId;

    TripManager.trips.removeWhere((trip) => trip.tripId == tripId);

    if (!mounted) return;

    setState(() {
      currentTrip = null;
      tripStatus = 'Scheduled';
      currentPosition = null;
      gpsActive = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip deleted successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ============================================================
  // GET GPS LOCATION
  // ============================================================

  Future<Position?> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please turn on GPS / Location service.'),
          backgroundColor: Colors.red,
        ),
      );

      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        if (!mounted) return null;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied.'),
            backgroundColor: Colors.red,
          ),
        );

        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission is permanently denied. '
            'Please enable it from Settings.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return position;
    } catch (e) {
      if (!mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to get GPS location: $e'),
          backgroundColor: Colors.red,
        ),
      );

      return null;
    }
  }

  // ============================================================
  // CONTINUOUS GPS
  // ============================================================

  void _startLocationTracking() {
    _positionSubscription?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) {
            if (!mounted || currentTrip == null || tripStatus != 'Live') {
              return;
            }

            final updatedTrip = BusTrip(
              tripId: currentTrip!.tripId,
              routeNo: currentTrip!.routeNo,
              busNumber: currentTrip!.busNumber,
              from: currentTrip!.from,
              to: currentTrip!.to,
              stops: currentTrip!.stops,
              departureDate: currentTrip!.departureDate,
              departureTime: currentTrip!.departureTime,
              status: 'Live',
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
            );

            setState(() {
              currentPosition = position;

              currentTrip = updatedTrip;
            });

            TripManager.updateTrip(updatedTrip);
          },
          onError: (error) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('GPS tracking error: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
  }

  // ============================================================
  // START TRIP
  // ============================================================

  Future<void> _startTrip() async {
    if (currentTrip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save the trip first.'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final position = await _getCurrentLocation();

    if (!mounted) return;

    if (position == null) {
      return;
    }

    final liveTrip = BusTrip(
      tripId: currentTrip!.tripId,
      routeNo: currentTrip!.routeNo,
      busNumber: currentTrip!.busNumber,
      from: currentTrip!.from,
      to: currentTrip!.to,
      stops: currentTrip!.stops,
      departureDate: currentTrip!.departureDate,
      departureTime: currentTrip!.departureTime,
      status: 'Live',
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );

    TripManager.updateTrip(liveTrip);

    setState(() {
      currentTrip = liveTrip;

      tripStatus = 'Live';

      gpsActive = true;

      currentPosition = position;
    });

    _startLocationTracking();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip started. GPS is active.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ============================================================
  // STOP TRIP
  // ============================================================

  void _stopTrip() {
    if (tripStatus != 'Live' || currentTrip == null) {
      return;
    }

    _positionSubscription?.cancel();
    _positionSubscription = null;

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
      latitude: null,
      longitude: null,
      accuracy: null,
    );

    TripManager.updateTrip(completedTrip);

    if (!mounted) return;

    setState(() {
      currentTrip = completedTrip;

      tripStatus = 'Completed';

      gpsActive = false;

      currentPosition = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip stopped successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  TimeOfDay? _parseTime(String value) {
    try {
      final text = value.trim();

      final match = RegExp(
        r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
        caseSensitive: false,
      ).firstMatch(text);

      if (match == null) {
        return null;
      }

      int hour = int.parse(match.group(1)!);
      final int minute = int.parse(match.group(2)!);
      final String period = match.group(3)!.toUpperCase();

      if (hour < 1 || hour > 12 || minute < 0 || minute > 59) {
        return null;
      }

      if (period == 'AM') {
        if (hour == 12) {
          hour = 0;
        }
      } else {
        if (hour != 12) {
          hour += 12;
        }
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (isLoadingBus) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Driver Trip Control'),
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
            // ====================================================
            // BUS INFORMATION
            // ====================================================
            Card(
              elevation: 3,
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

                    Row(
                      children: [
                        const Icon(Icons.directions_bus, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bus Number: ${widget.busNumber}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Route No: $routeNumber',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ====================================================
            // FROM
            // ====================================================
            const Text(
              'From',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            TextFormField(
              key: ValueKey('from_$fromLocation'),
              initialValue: fromLocation,
              enabled: tripStatus != 'Live',
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.trip_origin),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                fromLocation = value;
              },
            ),

            const SizedBox(height: 20),

            // ====================================================
            // SWITCH
            // ====================================================
            Center(
              child: IconButton(
                onPressed: tripStatus == 'Live'
                    ? null
                    : () {
                        setState(() {
                          final temp = fromLocation;

                          fromLocation = toLocation;

                          toLocation = temp;
                        });
                      },
                icon: const Icon(Icons.swap_vert, size: 35),
                tooltip: 'Switch From and To',
              ),
            ),

            // ====================================================
            // TO
            // ====================================================
            const Text(
              'To',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            TextFormField(
              key: ValueKey('to_$toLocation'),
              initialValue: toLocation,
              enabled: tripStatus != 'Live',
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                toLocation = value;
              },
            ),

            const SizedBox(height: 20),

            // ====================================================
            // DATE
            // ====================================================
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

            // ====================================================
            // TIME
            // ====================================================
            const Text(
              'Departure Time',
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

            // ====================================================
            // TRIP SUMMARY
            // ====================================================
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

                    const SizedBox(height: 12),

                    Text(
                      '$fromLocation → '
                      '$toLocation',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text('Route $routeNumber'),

                    const SizedBox(height: 6),

                    Text('Date: ${_formatDate(selectedDate)}'),

                    const SizedBox(height: 6),

                    Text('Time: ${selectedTime.format(context)}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ====================================================
            // STATUS
            // ====================================================
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

            // ====================================================
            // SAVE / UPDATE
            // ====================================================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: tripStatus == 'Live' ? null : _saveTrip,
                icon: const Icon(Icons.save),
                label: Text(
                  currentTrip == null ? 'SAVE TRIP' : 'UPDATE TRIP',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ====================================================
            // DELETE
            // ====================================================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: currentTrip != null && tripStatus != 'Live'
                    ? _deleteTrip
                    : null,
                icon: const Icon(Icons.delete_outline),
                label: const Text('DELETE TRIP'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ====================================================
            // START
            // ====================================================
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

            // ====================================================
            // STOP
            // ====================================================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: tripStatus == 'Live' ? _stopTrip : null,
                icon: const Icon(Icons.stop),
                label: const Text('STOP TRIP', style: TextStyle(fontSize: 17)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ====================================================
            // LIVE LOCATION
            // ====================================================
            if (tripStatus == 'Live')
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.gps_fixed, color: Colors.green),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Live Location',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (gpsActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
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
                        Text(
                          'Latitude: '
                          '${currentPosition!.latitude.toStringAsFixed(6)}',
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Longitude: '
                          '${currentPosition!.longitude.toStringAsFixed(6)}',
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Accuracy: '
                          '${currentPosition!.accuracy.toStringAsFixed(1)} m',
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
