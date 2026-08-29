import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_bus_screen.dart';

class OwnerRegistrationScreen extends StatefulWidget {
  const OwnerRegistrationScreen({super.key});

  @override
  State<OwnerRegistrationScreen> createState() =>
      _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState extends State<OwnerRegistrationScreen> {
  // ============================================================
  // REGISTRATION CONTROLLERS
  // ============================================================

  final ownerNameController = TextEditingController();
  final mobileController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // ============================================================
  // LOGIN CONTROLLERS
  // ============================================================

  final loginUsernameController = TextEditingController();
  final loginPasswordController = TextEditingController();

  bool hidePassword = true;
  bool hideLoginPassword = true;

  bool isRegistering = false;
  bool isLoggingIn = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // OWNER REGISTRATION
  // ============================================================

  Future<void> registerOwner() async {
    final ownerName = ownerNameController.text.trim();
    final mobile = mobileController.text.trim();
    final username = usernameController.text.trim().toLowerCase();
    final password = passwordController.text;

    if (ownerName.isEmpty ||
        mobile.isEmpty ||
        username.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all registration fields')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() {
      isRegistering = true;
    });

    try {
      // Firebase Authentication සඳහා internal email එකක්
      final authEmail = '$username@travelbuddy.app';

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: authEmail,
        password: password,
      );

      final user = userCredential.user;

      if (user == null) {
        throw Exception('Owner account could not be created.');
      }

      // Owner information Firestore එකේ save කිරීම
      await _firestore.collection('owners').doc(user.uid).set({
        'ownerId': user.uid,
        'ownerName': ownerName,
        'mobile': mobile,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Owner registration successful!'),
          backgroundColor: Colors.green,
        ),
      );

      // Registration successful.
      // Firebase user is already logged in.
      // Go directly to Add Bus screen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AddBusScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';

      if (e.code == 'email-already-in-use') {
        message = 'This username is already registered.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid username.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          isRegistering = false;
        });
      }
    }
  }

  // ============================================================
  // OWNER LOGIN
  // ============================================================

  Future<void> loginOwner() async {
    final username = loginUsernameController.text.trim().toLowerCase();
    final password = loginPasswordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password')),
      );
      return;
    }

    setState(() {
      isLoggingIn = true;
    });

    try {
      final authEmail = '$username@travelbuddy.app';

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: authEmail,
        password: password,
      );

      final user = userCredential.user;

      if (user == null) {
        throw Exception('Login failed.');
      }

      // Check owner profile
      final ownerDoc = await _firestore
          .collection('owners')
          .doc(user.uid)
          .get();

      if (!ownerDoc.exists) {
        await _auth.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Owner profile was not found.'),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Owner login successful!'),
          backgroundColor: Colors.green,
        ),
      );

      // Login successful.
      // Go directly to Add Bus screen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AddBusScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';

      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        message = 'Incorrect username or password.';
      } else if (e.code == 'user-disabled') {
        message = 'This owner account has been disabled.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoggingIn = false;
        });
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    ownerNameController.dispose();
    mobileController.dispose();
    usernameController.dispose();
    passwordController.dispose();

    loginUsernameController.dispose();
    loginPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Owner'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // ==================================================
            // REGISTER
            // ==================================================
            const Icon(Icons.directions_bus, size: 70, color: Colors.blue),

            const SizedBox(height: 15),

            const Text(
              'Register as Bus Owner',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: ownerNameController,
              decoration: const InputDecoration(
                labelText: 'Owner Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Example: tharangag',
                prefixIcon: Icon(Icons.account_circle),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: hidePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Minimum 6 characters',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    hidePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isRegistering ? null : registerOwner,
                icon: isRegistering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.app_registration),
                label: Text(
                  isRegistering ? 'Registering...' : 'Register Owner',
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ),

            // ==================================================
            // DIVIDER
            // ==================================================
            const SizedBox(height: 35),

            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 30),

            // ==================================================
            // LOGIN
            // ==================================================
            const Icon(Icons.login, size: 55, color: Colors.green),

            const SizedBox(height: 10),

            const Text(
              'Owner Login',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: loginUsernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.account_circle),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: loginPasswordController,
              obscureText: hideLoginPassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    hideLoginPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      hideLoginPassword = !hideLoginPassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isLoggingIn ? null : loginOwner,
                icon: isLoggingIn
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(
                  isLoggingIn ? 'Logging in...' : 'Owner Login',
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
