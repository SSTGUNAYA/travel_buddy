import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/account_session.dart';
import '../data/driver_session.dart';
import '../data/trip_manager.dart';
import 'edit_account_screen.dart';

class AccountDetailsScreen extends StatefulWidget {
  final String busNumber;

  const AccountDetailsScreen({super.key, required this.busNumber});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  bool isDeleting = false;
  bool hidePassword = true;

  Map<String, dynamic>? busData;

  // ------------------------------------------------------------
  // BUS DOCUMENT ID
  // ------------------------------------------------------------

  String get busId {
    return widget.busNumber.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]+'),
      '_',
    );
  }

  // ------------------------------------------------------------
  // CHECK ACTIVE / SCHEDULED TRIP
  // ------------------------------------------------------------

  bool get hasActiveTrip {
    return TripManager.getActiveTripByBusNumber(widget.busNumber) != null;
  }

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  // ------------------------------------------------------------
  // LOAD ACCOUNT
  // ------------------------------------------------------------

  Future<void> _loadAccount() async {
    try {
      final document = await _firestore.collection('buses').doc(busId).get();

      if (!mounted) return;

      if (!document.exists) {
        setState(() {
          isLoading = false;
          busData = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account was not found.'),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      setState(() {
        busData = document.data();
        isLoading = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load account: '
            '${e.message ?? e.code}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ------------------------------------------------------------
  // DELETE ACCOUNT
  // ------------------------------------------------------------

  Future<void> _deleteAccount() async {
    // ----------------------------------------------------------
    // 1. CHECK ACTIVE TRIP
    // ----------------------------------------------------------

    if (hasActiveTrip) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You cannot delete the account while a trip is scheduled or active.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ----------------------------------------------------------
    // 2. CONFIRM DELETE
    // ----------------------------------------------------------

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account?'),
          content: const Text(
            'This will permanently delete this bus account.\n\n'
            'Bus number, route information and account details '
            'will be deleted.\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('CANCEL'),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    // User cancelled
    if (confirmed != true) {
      return;
    }

    // ----------------------------------------------------------
    // 3. START DELETE
    // ----------------------------------------------------------

    if (!mounted) return;

    setState(() {
      isDeleting = true;
    });

    try {
      // --------------------------------------------------------
      // 4. DELETE BUS DOCUMENT FROM FIRESTORE
      // --------------------------------------------------------

      await _firestore.collection('buses').doc(busId).delete();

      // Delete related trips
      TripManager.deleteTripsByBusNumber(widget.busNumber);

      // Delete Firebase Authentication account
      final currentUser = _auth.currentUser;

      if (currentUser != null) {
        await currentUser.delete();
      }

      // Sign out from Firebase Authentication
      await _auth.signOut();

      // Logout Account Session
      AccountSession.logout();
      DriverSession.logout();
      // --------------------------------------------------------
      // 7. GO BACK TO REGISTER BUS PAGE
      // --------------------------------------------------------

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: ${e.message ?? e.code}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // ------------------------------------------------------------
  // EDIT ACCOUNT
  // ------------------------------------------------------------

  void _editAccount() {
    if (hasActiveTrip) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You cannot edit the account while a trip '
            'is scheduled or active.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAccountScreen(busNumber: widget.busNumber),
      ),
    ).then((_) {
      if (mounted) {
        _loadAccount();
      }
    });
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final activeTrip = TripManager.getActiveTripByBusNumber(widget.busNumber);

    final bool locked = activeTrip != null;

    // ----------------------------------------------------------
    // LOADING
    // ----------------------------------------------------------

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account Details'),
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),

        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ----------------------------------------------------------
    // ACCOUNT NOT FOUND
    // ----------------------------------------------------------

    if (busData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account Details'),
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),

        body: const Center(child: Text('Account information not found.')),
      );
    }

    final password = busData!['driverPassword']?.toString() ?? '';

    // ----------------------------------------------------------
    // MAIN SCREEN
    // ----------------------------------------------------------

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // ----------------------------------------------------
            // ICON
            // ----------------------------------------------------
            const Icon(Icons.account_circle, size: 90, color: Colors.blue),

            const SizedBox(height: 10),

            const Text(
              'Account Details',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            // ----------------------------------------------------
            // ACCOUNT INFORMATION CARD
            // ----------------------------------------------------
            Card(
              elevation: 3,

              child: Padding(
                padding: const EdgeInsets.all(18),

                child: Column(
                  children: [
                    // BUS NUMBER
                    _detailRow(
                      'Bus Number',
                      busData!['busNumber']?.toString() ?? '',
                      Icons.directions_bus,
                    ),

                    const Divider(),

                    // ROUTE
                    _detailRow(
                      'Route Number',
                      busData!['routeNumber']?.toString() ?? '',
                      Icons.route,
                    ),

                    const Divider(),

                    _detailRow(
                      'Bus Category',
                      busData!['busCategory']?.toString() ?? 'Not specified',
                      Icons.category,
                    ),

                    const Divider(),

                    // FROM
                    _detailRow(
                      'From',
                      busData!['from']?.toString() ?? '',
                      Icons.trip_origin,
                    ),

                    const Divider(),

                    // TO
                    _detailRow(
                      'To',
                      busData!['to']?.toString() ?? '',
                      Icons.location_on,
                    ),

                    const Divider(),

                    // DRIVER USERNAME
                    _detailRow(
                      'Driver Username',
                      busData!['driverUsername']?.toString() ?? '',
                      Icons.person,
                    ),

                    const Divider(),

                    // DRIVER PASSWORD
                    Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.grey),

                        const SizedBox(width: 12),

                        const Expanded(
                          child: Text(
                            'Driver Password',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),

                        Text(hidePassword ? '••••••••' : password),

                        IconButton(
                          onPressed: () {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
                          },

                          icon: Icon(
                            hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ----------------------------------------------------
            // LOCK MESSAGE
            // ----------------------------------------------------
            if (locked)
              Card(
                color: Colors.orange.shade50,

                child: const Padding(
                  padding: EdgeInsets.all(14),

                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'Account editing and deletion are '
                          'disabled while a trip is scheduled '
                          'or active.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // ----------------------------------------------------
            // EDIT ACCOUNT
            // ----------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 52,

              child: ElevatedButton.icon(
                onPressed: locked ? null : _editAccount,

                icon: const Icon(Icons.edit),

                label: const Text(
                  'EDIT ACCOUNT',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------
            // DELETE ACCOUNT
            // ----------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 52,

              child: OutlinedButton.icon(
                onPressed: locked || isDeleting ? null : _deleteAccount,

                icon: isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,

                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),

                label: Text(
                  isDeleting ? 'DELETING...' : 'DELETE ACCOUNT',

                  style: const TextStyle(fontSize: 16),
                ),

                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,

                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DETAIL ROW
  // ------------------------------------------------------------

  Widget _detailRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
