import 'package:flutter/material.dart';
import 'solar_profile/solar_profile.dart'; // Import your SolarProfileScreen

// If you have other top-level screens, you can import them too
// import 'maintenance/maintenance_home.dart';
// import 'blockchain_trading/trading_home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solar App Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange, // A theme color that fits solar
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // You can define a more complete theme here
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
        useMaterial3: true,
      ),
      // You can set SolarProfileScreen as the home directly if it's the main entry
      // home: const SolarProfileScreen(),
      // OR, create a simple home screen with a button to navigate to it
      home: const MainHomeScreen(),
      debugShowCheckedModeBanner: false, // Optional: removes the debug banner
    );
  }
}

class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar App Demo Home'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to the Solar Application!',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SolarProfileScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16)),
              child: const Text('Go to Solar Profile & Tools'),
            ),
            const SizedBox(height: 20),
            // Add buttons for other sections if you want to test them from here
            /*
            ElevatedButton(
              onPressed: () {
                // Navigator.push(context, MaterialPageRoute(builder: (context) => const MaintenanceHomeScreen()));
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Maintenance Home (Not Implemented)')),
                );
              },
              child: const Text('Go to Maintenance'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigator.push(context, MaterialPageRoute(builder: (context) => const TradingHomeScreen()));
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Blockchain Trading (Not Implemented)')),
                );
              },
              child: const Text('Go to Blockchain Trading'),
            ),
            */
          ],
        ),
      ),
    );
  }
}
