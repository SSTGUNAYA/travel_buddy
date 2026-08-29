import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddBusScreen extends StatefulWidget {
  const AddBusScreen({super.key});

  @override
  State<AddBusScreen> createState() => _AddBusScreenState();
}

class _AddBusScreenState extends State<AddBusScreen> {
  final busNumberController = TextEditingController();
  final routeNumberController = TextEditingController();
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final driverPasswordController = TextEditingController();

  bool isSaving = false;
  bool hideDriverPassword = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveBus() async {
    final busNumber = busNumberController.text.trim().toUpperCase();
    final routeNumber = routeNumberController.text.trim();
    final from = fromController.text.trim();
    final to = toController.text.trim();
    final driverPassword = driverPasswordController.text;

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (busNumber.isEmpty ||
        routeNumber.isEmpty ||
        from.isEmpty ||
        to.isEmpty ||
        driverPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (driverPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // --------------------------------------------------------
      // BUS NUMBER AS UNIQUE DOCUMENT ID
      // --------------------------------------------------------

      final busId = busNumber.replaceAll(RegExp(r'[^A-Z0-9]+'), '_');

      final busRef = _firestore.collection('buses').doc(busId);

      // --------------------------------------------------------
      // CHECK DUPLICATE BUS NUMBER
      // --------------------------------------------------------

      final existingBus = await busRef.get();

      if (existingBus.exists) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This bus number is already registered.'),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      // --------------------------------------------------------
      // SAVE BUS
      // --------------------------------------------------------

      await busRef.set({
        'busId': busId,
        'busNumber': busNumber,
        'routeNumber': routeNumber,
        'from': from,
        'to': to,
        'driverUsername': busNumber,
        'driverPassword': driverPassword,
        'status': 'inactive',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bus $busNumber registered successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save bus: ${e.message ?? e.code}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    busNumberController.dispose();
    routeNumberController.dispose();
    fromController.dispose();
    toController.dispose();
    driverPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Register'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.directions_bus, size: 75, color: Colors.blue),

            const SizedBox(height: 15),

            const Text(
              'Register Your Bus',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

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
              obscureText: hideDriverPassword,
              decoration: InputDecoration(
                labelText: 'Driver Password',
                hintText: 'Minimum 6 characters',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    hideDriverPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      hideDriverPassword = !hideDriverPassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Driver username will be the Bus Number.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : saveBus,
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  isSaving ? 'Saving...' : 'Save Bus',
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
