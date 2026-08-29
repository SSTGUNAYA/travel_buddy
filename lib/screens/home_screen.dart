import '../data/driver_session.dart';
import 'driver_login_screen.dart';
import 'driver_trip_control_screen.dart';

import 'package:flutter/material.dart';
import 'add_bus_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Buddy'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.directions_bus,
                        size: 85,
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'Travel Buddy',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Your Smart Travel Companion',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),

                      const SizedBox(height: 40),

                      // ------------------------------------------------
                      // REGISTER BUS
                      // ------------------------------------------------
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddBusScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.directions_bus),
                          label: const Text(
                            'Register Bus',
                            style: TextStyle(fontSize: 17),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ------------------------------------------------
                      // DRIVER LOGIN
                      // ------------------------------------------------
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (DriverSession.isLoggedIn) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DriverTripControlScreen(
                                    busNumber: DriverSession.busNumber!,
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const DriverLoginScreen(),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.person),
                          label: const Text(
                            'Driver Login',
                            style: TextStyle(fontSize: 17),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ------------------------------------------------
                      // SEARCH BUS
                      // ------------------------------------------------
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.search),
                          label: const Text(
                            'Search Bus',
                            style: TextStyle(fontSize: 17),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ----------------------------------------------------------
            // ROUND HOME BUTTON
            // ----------------------------------------------------------
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.home, size: 30, color: Colors.white),
                  tooltip: 'Home',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
