// lib/screens/demo_main_home_screen.dart
import 'package:flutter/material.dart';
// Assuming SolarProfileScreen is in solar_profile/solar_profile_screening.dart
// and the class name inside is SolarProfileScreen
import '../solar_profile/solar_profile_screening.dart';

class DemoMainHomeScreen extends StatelessWidget {
  // It's good practice to define a routeName for screens you navigate to by name
  static const routeName = '/demo-home';
  const DemoMainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Use a distinct title to differentiate from the main app's home/hub
        title: const Text('Solar Demo Section'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to the Solar Demo!',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navigate to the SolarProfileScreen
                // This assumes SolarProfileScreen can be instantiated without arguments
                // or handles the case where no arguments are passed (e.g., shows generic info).
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SolarProfileScreen()),
                );
                // If SolarProfileScreen has a routeName defined and registered in main.dart:
                // Navigator.of(context).pushNamed(SolarProfileScreen.routeName);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black, // For better contrast on orangeAccent
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              child: const Text('Go to Demo Solar Profile Tools'),
            ),
            const SizedBox(height: 20),
            // Your other commented-out buttons if they are part of this demo
          ],
        ),
      ),
    );
  }
}