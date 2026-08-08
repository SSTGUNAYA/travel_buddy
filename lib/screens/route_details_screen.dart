import 'package:flutter/material.dart';
import '../data/bus_routes.dart';

class RouteDetailsScreen extends StatelessWidget {
  final BusRoute route;

  const RouteDetailsScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Route ${route.routeNo}"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${route.from} → ${route.to}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Text(
              "Estimated Time: ${route.estimatedTime}",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 25),

            const Text(
              "Bus Stops",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: route.stops.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.blue),
                    title: Text(route.stops[index]),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Live Bus Location will be added later.
                },
                icon: const Icon(Icons.location_on),
                label: const Text("View Live Bus"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
