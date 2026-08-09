import 'package:flutter/material.dart';
import '../data/bus_routes.dart';

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

  DateTime selectedDate = DateTime.now();

  TimeOfDay selectedTime = const TimeOfDay(hour: 6, minute: 30);

  String tripStatus = 'Scheduled';

  @override
  void initState() {
    super.initState();

    fromLocation = selectedRoute.from;
    toLocation = selectedRoute.to;
  }

  // Change route
  void _changeRoute(BusRoute? route) {
    if (route == null) return;

    setState(() {
      selectedRoute = route;
      fromLocation = route.from;
      toLocation = route.to;
      tripStatus = 'Scheduled';
    });
  }

  // Switch From and To
  void _switchRoute() {
    setState(() {
      final temp = fromLocation;
      fromLocation = toLocation;
      toLocation = temp;
    });
  }

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

  Future<void> _selectDate() async {
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

  Future<void> _selectTime() async {
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

  void _saveSchedule() {
    setState(() {
      tripStatus = 'Scheduled';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip schedule saved successfully')),
    );
  }

  void _startTrip() {
    setState(() {
      tripStatus = 'Live';
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Trip started successfully')));
  }

  void _completeTrip() {
    setState(() {
      tripStatus = 'Completed';
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Trip completed')));
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

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
            // BUS INFORMATION
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

            // SELECT ROUTE
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

              onChanged: _changeRoute,
            ),

            const SizedBox(height: 20),

            // FROM
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

              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  fromLocation = value;
                });
              },
            ),

            const SizedBox(height: 10),

            // SWITCH BUTTON
            Center(
              child: IconButton(
                onPressed: tripStatus == 'Live' ? null : _switchRoute,

                icon: const Icon(Icons.swap_vert, size: 35),

                tooltip: 'Switch From and To',
              ),
            ),

            // TO
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

              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  toLocation = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // DATE
            const Text(
              'Departure Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: _selectDate,

                icon: const Icon(Icons.calendar_month),

                label: Text(_formatDate(selectedDate)),
              ),
            ),

            const SizedBox(height: 20),

            // TIME
            const Text(
              'Scheduled Departure Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: _selectTime,

                icon: const Icon(Icons.access_time),

                label: Text(selectedTime.format(context)),
              ),
            ),

            const SizedBox(height: 20),

            // TRIP SUMMARY
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
                      '$fromLocation → $toLocation',
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

            // STATUS
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

            // SAVE
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

            // START TRIP
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
              ),
            ),

            const SizedBox(height: 15),

            // COMPLETE
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

            // LIVE LOCATION
            if (tripStatus == 'Live')
              Card(
                child: ListTile(
                  leading: const Icon(Icons.gps_fixed, color: Colors.green),

                  title: const Text(
                    'Live Location',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: const Text(
                    'Location tracking '
                    'will be connected '
                    'in the next step.',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
