import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'owner_buses_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String ownerName = 'Bus Owner';

  @override
  void initState() {
    super.initState();
    _loadOwnerData();
  }

  Future<void> _loadOwnerData() async {
    final user = _auth.currentUser;

    if (user == null) return;

    try {
      final document = await _firestore
          .collection('owners')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (document.exists) {
        final data = document.data();

        setState(() {
          ownerName = data?['ownerName'] ?? 'Bus Owner';
        });
      }
    } catch (e) {
      // Owner data loading error
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.pop(context);
  }

  void _openMyBuses() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OwnerBusesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // =====================================================
            // OWNER INFORMATION
            // =====================================================
            Card(
              elevation: 3,

              child: Padding(
                padding: const EdgeInsets.all(18),

                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person, size: 35),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'Welcome',
                            style: TextStyle(color: Colors.grey),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            ownerName,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          if (user != null)
                            const Text(
                              'Owner account active',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // =====================================================
            // MY BUSES TITLE
            // =====================================================
            const Text(
              'My Buses',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            // =====================================================
            // MY BUSES CARD
            // =====================================================
            Card(
              elevation: 3,

              child: InkWell(
                onTap: _openMyBuses,

                borderRadius: BorderRadius.circular(12),

                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Row(
                    children: [
                      Container(
                        width: 65,
                        height: 65,

                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),

                          borderRadius: BorderRadius.circular(15),
                        ),

                        child: const Icon(
                          Icons.directions_bus,
                          size: 38,
                          color: Colors.blue,
                        ),
                      ),

                      const SizedBox(width: 18),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              'Manage My Buses',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 7),

                            Text(
                              'View, add and manage your registered buses.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // =====================================================
            // ADD BUS BUTTON
            // =====================================================
            SizedBox(
              width: double.infinity,
              height: 52,

              child: ElevatedButton.icon(
                onPressed: _openMyBuses,

                icon: const Icon(Icons.directions_bus),

                label: const Text(
                  'View My Buses',
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // =====================================================
            // INFORMATION
            // =====================================================
            Card(
              color: Colors.blue.withValues(alpha: 0.06),

              child: const Padding(
                padding: EdgeInsets.all(16),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Only buses registered under your owner account will be displayed in My Buses.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
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
