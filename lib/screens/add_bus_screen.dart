import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'account_login_screen.dart';

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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveBus() async {
    final busNumber = busNumberController.text.trim().toUpperCase();
    final routeNumber = routeNumberController.text.trim();
    final from = fromController.text.trim();
    final to = toController.text.trim();
    final driverPassword = driverPasswordController.text;
    final busCategory = selectedBusCategory!;

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

    if (selectedBusCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Bus Category'),
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

    UserCredential? credential;

    try {
      // ----------------------------------------------------------
      // BUS ID
      // ----------------------------------------------------------

      final busId = busNumber.replaceAll(RegExp(r'[^A-Z0-9]+'), '_');

      final busRef = _firestore.collection('buses').doc(busId);

      // ----------------------------------------------------------
      // 1. CHECK DUPLICATE BUS NUMBER FIRST
      // ----------------------------------------------------------

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

      // ----------------------------------------------------------
      // 2. CREATE FIREBASE AUTH ACCOUNT
      // ----------------------------------------------------------

      final authEmail = '$busNumber@travelbuddy.app';

      credential = await _auth.createUserWithEmailAndPassword(
        email: authEmail,
        password: driverPassword,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Firebase account could not be created.');
      }

      final uid = user.uid;

      // ----------------------------------------------------------
      // 3. SAVE BUS DATA TO FIRESTORE
      // ----------------------------------------------------------

      await busRef.set({
        'busId': busId,
        'busNumber': busNumber,
        'busCategory': busCategory,
        'routeNumber': routeNumber,
        'from': from,
        'to': to,
        'driverUsername': busNumber,
        'driverPassword': driverPassword,
        'ownerUid': uid,
        'status': 'inactive',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ----------------------------------------------------------
      // 4. SIGN OUT AFTER REGISTRATION
      // ----------------------------------------------------------

      await _auth.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bus $busNumber registered successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // ----------------------------------------------------------
      // 5. RETURN TO BUS REGISTER PAGE
      // ----------------------------------------------------------

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      // ----------------------------------------------------------
      // AUTH ERROR
      // ----------------------------------------------------------

      if (mounted) {
        String message;

        if (e.code == 'email-already-in-use') {
          message = 'This bus account already exists.';
        } else if (e.code == 'weak-password') {
          message = 'Password is too weak.';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid bus account information.';
        } else {
          message = 'Account creation failed: ${e.message ?? e.code}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } on FirebaseException catch (e) {
      // ----------------------------------------------------------
      // FIRESTORE ERROR
      // ----------------------------------------------------------

      // If Firestore save failed after Auth account creation,
      // remove the newly created Auth account.
      try {
        await credential?.user?.delete();
      } catch (_) {}

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save bus account: ${e.message ?? e.code}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // ----------------------------------------------------------
      // OTHER ERROR
      // ----------------------------------------------------------

      try {
        await credential?.user?.delete();
      } catch (_) {}

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
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'account_login') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountLoginScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'account_login',
                child: Row(
                  children: [
                    Icon(Icons.account_circle),
                    SizedBox(width: 10),
                    Text('Account Login'),
                  ],
                ),
              ),
            ],
          ),
        ],
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
