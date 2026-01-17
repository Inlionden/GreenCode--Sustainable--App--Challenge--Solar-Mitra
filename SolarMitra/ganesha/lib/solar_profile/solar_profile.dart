// lib/solar_profile/solar_profile.dart
import 'package:flutter/material.dart';
import 'solar_estimator.dart';        // Ensure these files exist in this directory
import 'panel_angle_calculator.dart';  // or provide correct relative paths

class SolarProfileScreen extends StatelessWidget {
  // It's good practice to define a routeName for screens you navigate to by name
  static const routeName = '/solar-profile-tools'; // Changed to be more specific
  const SolarProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This version of SolarProfileScreen is a simple navigation hub for tools.
    // It does not currently fetch or display user-specific profile data from UserSession or arguments.
    // If you need it to display user info when called from TradingHubScreen,
    // you'd make this a StatefulWidget and handle arguments or UserSession.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Profile & Tools'),
        // Example of matching the main app's theme if desired
        // backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // You could add a header here if needed:
          // Padding(
          //   padding: const EdgeInsets.only(bottom: 16.0),
          //   child: Text(
          //     "Explore Solar Utilities",
          //     style: Theme.of(context).textTheme.headlineSmall,
          //     textAlign: TextAlign.center,
          //   ),
          // ),
          _buildToolCard(
            context,
            icon: Icons.calculate_outlined,
            title: 'Solar Energy Estimator',
            subtitle: 'Estimate potential solar energy generation.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SolarEstimatorScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildToolCard(
            context,
            icon: Icons.solar_power_outlined, // Could also be Icons.explore_outlined or similar
            title: 'Panel Angle Calculator',
            subtitle: 'Calculate optimal solar panel tilt angles.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PanelAngleCalculatorScreen()),
              );
            },
          ),
          // Add more tool cards here if needed
          // e.g., for apsl_sun_calc if it's a user-facing tool
        ],
      ),
    );
  }

  Widget _buildToolCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[700])),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }
}