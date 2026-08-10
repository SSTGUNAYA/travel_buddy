import '../data/bus_routes.dart';
import 'package:flutter/material.dart';
import 'bus_timetable_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();

  List<BusRoute> filteredRoutes = busRoutes;
  void searchBus() {
    final query = searchController.text.toLowerCase();

    setState(() {
      filteredRoutes = busRoutes.where((route) {
        return route.routeNo.toLowerCase().contains(query) ||
            route.from.toLowerCase().contains(query) ||
            route.to.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Bus"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: (value) {
                searchBus();
              },
              decoration: InputDecoration(
                hintText: "Enter Bus Number or Route",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: filteredRoutes.length,
                itemBuilder: (context, index) {
                  final route = filteredRoutes[index];

                  return Card(
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BusTimetableScreen(routeNo: route.routeNo),
                          ),
                        );
                      },

                      leading: const Icon(Icons.directions_bus),
                      title: Text(
                        "${route.routeNo} - ${route.from} → ${route.to}",
                      ),
                      subtitle: Text("Estimated Time: ${route.estimatedTime}"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
