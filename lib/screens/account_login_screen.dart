import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/account_session.dart';
import 'account_details_screen.dart';

class AccountLoginScreen extends StatefulWidget {
  const AccountLoginScreen({super.key});

  @override
  State<AccountLoginScreen> createState() => _AccountLoginScreenState();
}

class _AccountLoginScreenState extends State<AccountLoginScreen> {
  final busNumberController = TextEditingController();
  final passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoggingIn = false;
  bool hidePassword = true;

  Future<void> loginAccount() async {
    final busNumber = busNumberController.text.trim().toUpperCase();
    final password = passwordController.text;

    // ----------------------------------------------------------
    // 1. VALIDATION
    // ----------------------------------------------------------

    if (busNumber.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Bus Number and Password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoggingIn = true;
    });

    try {
      // --------------------------------------------------------
      // 2. SAME EMAIL CREATED DURING BUS REGISTRATION
      // --------------------------------------------------------

      final authEmail = '$busNumber@travelbuddy.app';

      // --------------------------------------------------------
      // 3. FIREBASE AUTH LOGIN
      // --------------------------------------------------------

      await _auth.signInWithEmailAndPassword(
        email: authEmail,
        password: password,
      );

      // --------------------------------------------------------
      // 4. ACCOUNT SESSION
      // --------------------------------------------------------

      AccountSession.login(busNumber);

      if (!mounted) return;

      // --------------------------------------------------------
      // 5. OPEN ACCOUNT DETAILS
      // --------------------------------------------------------

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AccountDetailsScreen(busNumber: busNumber),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Incorrect Bus Number or Password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid Bus Number.';
      } else {
        message = 'Login failed: ${e.message ?? e.code}';
      }

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

  @override
  void dispose() {
    busNumberController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Login'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 35),

            const Icon(Icons.account_circle, size: 90, color: Colors.blue),

            const SizedBox(height: 20),

            const Text(
              'Account Login',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              'Manage your bus account',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),

            const SizedBox(height: 35),

            // --------------------------------------------------
            // BUS NUMBER
            // --------------------------------------------------
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

            const SizedBox(height: 18),

            // --------------------------------------------------
            // PASSWORD
            // --------------------------------------------------
            TextField(
              controller: passwordController,
              obscureText: hidePassword,
              decoration: InputDecoration(
                labelText: 'Account Password',
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

            const SizedBox(height: 30),

            // --------------------------------------------------
            // LOGIN BUTTON
            // --------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 52,

              child: ElevatedButton.icon(
                onPressed: isLoggingIn ? null : loginAccount,

                icon: isLoggingIn
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),

                label: Text(
                  isLoggingIn ? 'Logging in...' : 'Account Login',

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
