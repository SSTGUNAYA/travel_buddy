import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OwnerBusesScreen extends StatefulWidget {
  const OwnerBusesScreen({super.key});

  @override
  State<OwnerBusesScreen> createState() => _OwnerBusesScreenState();
}

class _OwnerBusesScreenState extends State<OwnerBusesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // ADD BUS
  // ============================================================

  Future<void> _addBus() async {
    final busNumberController = TextEditingController();
    final routeNumberController = TextEditingController();
    final fromController = TextEditingController();
    final toController = TextEditingController();
    final driverPasswordController = TextEditingController();

    bool hidePassword = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Bus'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: busNumberController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Bus Number',
                        hintText: 'Example: NB-1234',
                        prefixIcon: Icon(Icons.directions_bus),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: routeNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Route Number',
                        hintText: 'Example: 138',
                        prefixIcon: Icon(Icons.route),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: fromController,
                      decoration: const InputDecoration(
                        labelText: 'From',
                        prefixIcon: Icon(Icons.trip_origin),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: toController,
                      decoration: const InputDecoration(
                        labelText: 'To',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: driverPasswordController,
                      obscureText: hidePassword,
                      decoration: InputDecoration(
                        labelText: 'Driver Password',
                        hintText: 'Minimum 6 characters',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              hidePassword = !hidePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton.icon(
                  onPressed: () async {
                    final busNumber = busNumberController.text
                        .trim()
                        .toUpperCase();

                    final routeNumber = routeNumberController.text.trim();

                    final from = fromController.text.trim();

                    final to = toController.text.trim();

                    final driverPassword = driverPasswordController.text;

                    if (busNumber.isEmpty ||
                        routeNumber.isEmpty ||
                        from.isEmpty ||
                        to.isEmpty ||
                        driverPassword.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    if (driverPassword.length < 6) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Driver password must be at least 6 characters',
                          ),
                        ),
                      );
                      return;
                    }

                    final user = _auth.currentUser;

                    if (user == null) {
                      Navigator.of(dialogContext).pop(false);
                      return;
                    }

                    try {
                      final busId = busNumber.replaceAll(
                        RegExp(r'[^A-Z0-9]+'),
                        '_',
                      );

                      final busRef = _firestore.collection('buses').doc(busId);

                      final existingBus = await busRef.get();

                      if (existingBus.exists) {
                        if (!dialogContext.mounted) return;

                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'This bus number is already registered.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );

                        return;
                      }

                      await busRef.set({
                        'busId': busId,
                        'busNumber': busNumber,
                        'ownerId': user.uid,
                        'routeNumber': routeNumber,
                        'from': from,
                        'to': to,
                        'driverPassword': driverPassword,
                        'status': 'inactive',
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (!dialogContext.mounted) return;

                      Navigator.of(dialogContext).pop(true);
                    } on FirebaseException catch (e) {
                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to save bus: '
                            '${e.message ?? e.code}',
                          ),
                        ),
                      );
                    }
                  },

                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    busNumberController.dispose();
    routeNumberController.dispose();
    fromController.dispose();
    toController.dispose();
    driverPasswordController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bus registered successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ============================================================
  // EDIT BUS
  // ============================================================

  Future<void> _editBus(String busId, Map<String, dynamic> bus) async {
    final routeController = TextEditingController(
      text: bus['routeNumber'] ?? '',
    );

    final fromController = TextEditingController(text: bus['from'] ?? '');

    final toController = TextEditingController(text: bus['to'] ?? '');

    final busNumber = bus['busNumber'] ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit $busNumber'),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Bus Number',
                    prefixIcon: const Icon(Icons.directions_bus),
                    border: const OutlineInputBorder(),
                    hintText: busNumber,
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: routeController,
                  decoration: const InputDecoration(
                    labelText: 'Route Number',
                    prefixIcon: Icon(Icons.route),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: fromController,
                  decoration: const InputDecoration(
                    labelText: 'From',
                    prefixIcon: Icon(Icons.trip_origin),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: toController,
                  decoration: const InputDecoration(
                    labelText: 'To',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton.icon(
              onPressed: () async {
                final route = routeController.text.trim();
                final from = fromController.text.trim();
                final to = toController.text.trim();

                if (route.isEmpty || from.isEmpty || to.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                try {
                  await _firestore.collection('buses').doc(busId).update({
                    'routeNumber': route,
                    'from': from,
                    'to': to,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (!dialogContext.mounted) return;

                  Navigator.of(dialogContext).pop(true);
                } on FirebaseException catch (e) {
                  if (!dialogContext.mounted) return;

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to update bus: '
                        '${e.message ?? e.code}',
                      ),
                    ),
                  );
                }
              },

              icon: const Icon(Icons.save),
              label: const Text('Update'),
            ),
          ],
        );
      },
    );

    routeController.dispose();
    fromController.dispose();
    toController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bus updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ============================================================
  // UPDATE DRIVER PASSWORD
  // ============================================================

  Future<void> _updateDriverPassword(String busId, String busNumber) async {
    final passwordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Driver Password - $busNumber'),

          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New Driver Password',
              hintText: 'Minimum 6 characters',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton.icon(
              onPressed: () async {
                final password = passwordController.text;

                if (password.length < 6) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                    ),
                  );
                  return;
                }

                try {
                  await _firestore.collection('buses').doc(busId).update({
                    'driverPassword': password,
                    'passwordUpdatedAt': FieldValue.serverTimestamp(),
                  });

                  if (!dialogContext.mounted) return;

                  Navigator.of(dialogContext).pop(true);
                } on FirebaseException catch (e) {
                  if (!dialogContext.mounted) return;

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to update password: '
                        '${e.message ?? e.code}',
                      ),
                    ),
                  );
                }
              },

              icon: const Icon(Icons.lock_reset),
              label: const Text('Update'),
            ),
          ],
        );
      },
    );

    passwordController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver password updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ============================================================
  // DELETE BUS
  // ============================================================

  Future<void> _deleteBus(String busId, String busNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Bus'),

          content: Text('Are you sure you want to delete bus $busNumber?'),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),

              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },

              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection('buses').doc(busId).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bus $busNumber deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete bus: ${e.message ?? e.code}')),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Buses'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Please login as owner first.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Buses'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBus,
        icon: const Icon(Icons.add),
        label: const Text('Add Bus'),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('buses')
            .where('ownerId', isEqualTo: user.uid)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading buses:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final buses = snapshot.data?.docs ?? [];

          if (buses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.directions_bus_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'No buses registered yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _addBus,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Bus'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 90),
            itemCount: buses.length,

            itemBuilder: (context, index) {
              final document = buses[index];

              final bus = document.data();

              final busId = document.id;

              final busNumber = bus['busNumber'] ?? 'Unknown';

              final routeNumber = bus['routeNumber'] ?? '-';

              final from = bus['from'] ?? '-';

              final to = bus['to'] ?? '-';

              final status = bus['status'] ?? 'inactive';

              final isActive = status == 'active';

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 3,

                child: Padding(
                  padding: const EdgeInsets.all(15),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // BUS HEADER
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 27,
                            backgroundColor: Colors.blue,

                            child: Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  busNumber,
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  'Route $routeNumber',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),

                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.grey.withValues(alpha: 0.15),

                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: Text(
                              isActive ? 'ACTIVE' : 'INACTIVE',

                              style: TextStyle(
                                color: isActive ? Colors.green : Colors.grey,

                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 25),

                      // ROUTE
                      Row(
                        children: [
                          const Icon(
                            Icons.trip_origin,
                            size: 20,
                            color: Colors.blue,
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              from,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),

                          const Icon(Icons.arrow_forward, color: Colors.grey),

                          const SizedBox(width: 8),

                          const Icon(
                            Icons.location_on,
                            size: 20,
                            color: Colors.red,
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              to,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // EDIT + PASSWORD
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _editBus(busId, bus);
                              },

                              icon: const Icon(Icons.edit),

                              label: const Text('Edit'),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _updateDriverPassword(busId, busNumber);
                              },

                              icon: const Icon(Icons.lock_reset),

                              label: const Text('Driver PW'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // DELETE
                      SizedBox(
                        width: double.infinity,

                        child: OutlinedButton.icon(
                          onPressed: () {
                            _deleteBus(busId, busNumber);
                          },

                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),

                          icon: const Icon(Icons.delete_outline),

                          label: const Text('Delete Bus'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
