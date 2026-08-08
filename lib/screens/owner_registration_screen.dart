import 'package:flutter/material.dart';

class OwnerRegistrationScreen extends StatefulWidget {
  const OwnerRegistrationScreen({super.key});

  @override
  State<OwnerRegistrationScreen> createState() =>
      _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState extends State<OwnerRegistrationScreen> {
  final ownerNameController = TextEditingController();
  final mobileController = TextEditingController();
  final busNumberController = TextEditingController();
  final routeNumberController = TextEditingController();
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bus Owner Registration"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.directions_bus, size: 70, color: Colors.blue),

            const SizedBox(height: 15),

            const Text(
              "Register Your Bus",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: ownerNameController,
              decoration: const InputDecoration(
                labelText: "Owner Name",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Mobile Number",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: busNumberController,
              decoration: const InputDecoration(
                labelText: "Bus Number",
                hintText: "Example: NB-1234",
                prefixIcon: Icon(Icons.directions_bus),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: routeNumberController,
              decoration: const InputDecoration(
                labelText: "Route Number",
                hintText: "Example: 138",
                prefixIcon: Icon(Icons.route),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: fromController,
              decoration: const InputDecoration(
                labelText: "From",
                prefixIcon: Icon(Icons.trip_origin),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: toController,
              decoration: const InputDecoration(
                labelText: "To",
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: hidePassword,
              decoration: InputDecoration(
                labelText: "Password",
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

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (ownerNameController.text.isEmpty ||
                      mobileController.text.isEmpty ||
                      busNumberController.text.isEmpty ||
                      routeNumberController.text.isEmpty ||
                      fromController.text.isEmpty ||
                      toController.text.isEmpty ||
                      passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Bus ${busNumberController.text} is ready for registration",
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.app_registration),
                label: const Text(
                  "Register Bus",
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
