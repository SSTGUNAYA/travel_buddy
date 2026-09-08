import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/trip_manager.dart';

class EditAccountScreen extends StatefulWidget {
  final String busNumber;

  const EditAccountScreen({super.key, required this.busNumber});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final routeController = TextEditingController();
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  bool hidePassword = true;

  String? selectedBusCategory;

  final List<String> busCategories = [
    'CTB Normal',
    'CTB AC',
    'CTB Highway',
    'Private Normal',
    'Private Semi',
    'Private AC',
    'Private Highway',
  ];

  String get busId => widget.busNumber.trim().toUpperCase().replaceAll(
    RegExp(r'[^A-Z0-9]+'),
    '_',
  );

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  // ============================================================
  // LOAD ACCOUNT
  // ============================================================

  Future<void> _loadAccount() async {
    try {
      final document = await _firestore.collection('buses').doc(busId).get();

      if (!mounted) return;

      if (!document.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account not found.'),
            backgroundColor: Colors.red,
          ),
        );

        Navigator.pop(context);
        return;
      }

      final data = document.data();

      if (data == null) {
        Navigator.pop(context);
        return;
      }

      routeController.text = data['routeNumber']?.toString() ?? '';

      fromController.text = data['from']?.toString() ?? '';

      toController.text = data['to']?.toString() ?? '';

      passwordController.text = data['driverPassword']?.toString() ?? '';

      final savedCategory = data['busCategory']?.toString();

      setState(() {
        if (savedCategory != null && busCategories.contains(savedCategory)) {
          selectedBusCategory = savedCategory;
        } else {
          selectedBusCategory = null;
        }

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading account: $e'),
          backgroundColor: Colors.red,
        ),
      );

      Navigator.pop(context);
    }
  }

  // ============================================================
  // SAVE CHANGES
  // ============================================================

  Future<void> _saveChanges() async {
    if (TripManager.getActiveTripByBusNumber(widget.busNumber) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot edit account while a trip is scheduled or active.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final route = routeController.text.trim();
    final from = fromController.text.trim();
    final to = toController.text.trim();
    final password = passwordController.text;

    if (route.isEmpty || from.isEmpty || to.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedBusCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Bus Category.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await _firestore.collection('buses').doc(busId).update({
        'routeNumber': route,
        'busCategory': selectedBusCategory,
        'from': from,
        'to': to,
        'driverPassword': password,
        'driverUsername': widget.busNumber,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update account: '
            '${e.message ?? e.code}',
          ),
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

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    routeController.dispose();
    fromController.dispose();
    toController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Account'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Account'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // ==================================================
            // BUS NUMBER
            // ==================================================
            TextField(
              controller: TextEditingController(text: widget.busNumber),
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Bus Number',
                prefixIcon: Icon(Icons.directions_bus),
                suffixIcon: Icon(Icons.lock, color: Colors.grey),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bus Number is the account identity and cannot be changed.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ROUTE NUMBER
            // ==================================================
            TextField(
              controller: routeController,
              decoration: const InputDecoration(
                labelText: 'Route Number',
                prefixIcon: Icon(Icons.route),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // BUS CATEGORY
            // ==================================================
            DropdownButtonFormField<String>(
              initialValue: selectedBusCategory,
              decoration: const InputDecoration(
                labelText: 'Bus Category',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select Bus Category'),
              items: busCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedBusCategory = value;
                });
              },
            ),

            const SizedBox(height: 15),

            // ==================================================
            // FROM
            // ==================================================
            TextField(
              controller: fromController,
              decoration: const InputDecoration(
                labelText: 'From',
                prefixIcon: Icon(Icons.trip_origin),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // TO
            // ==================================================
            TextField(
              controller: toController,
              decoration: const InputDecoration(
                labelText: 'To',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // DRIVER PASSWORD
            // ==================================================
            TextField(
              controller: passwordController,
              obscureText: hidePassword,
              decoration: InputDecoration(
                labelText: 'Driver Password',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },
                  icon: Icon(
                    hidePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // SAVE
            // ==================================================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _saveChanges,
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  isSaving ? 'SAVING...' : 'SAVE CHANGES',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
