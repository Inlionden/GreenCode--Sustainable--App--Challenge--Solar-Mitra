// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Import your main SolarMitraApp screens
import 'screens/auth_screen.dart';
import 'screens/trading_hub_screen.dart';
import 'screens/posw_simulation_screen.dart';
import 'screens/energy_market_screen.dart';
import 'screens/demo_main_home_screen.dart';    // For the alternative demo entry

// <<< UPDATED IMPORT to point to your main solar profile file >>>
import 'solar_profile/solar_profile.dart'; // Assuming SolarProfileScreen class is in this file

// Import firebase_options.dart
import 'firebase_options.dart';
// Import User Session Manager
import 'services/user_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(SolarMitraApp());
}

class SolarMitraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SolarMitra App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
          brightness: Brightness.light,
        ).copyWith(
          secondary: Colors.orangeAccent[700],
          inversePrimary: Colors.teal[700],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom()
        ),
        appBarTheme: AppBarTheme(),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: UserSession.isLoggedIn(),
        builder: (ctx, sessionSnapshot) {
          if (sessionSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (sessionSnapshot.hasData && sessionSnapshot.data == true) {
            return TradingHubScreen();
          }
          // Default to AuthScreen if not logged in.
          // If you want DemoMainHomeScreen as the very first screen before auth:
          // return const DemoMainHomeScreen();
          return AuthScreen();
        },
      ),
      routes: {
        AuthScreen.routeName: (ctx) => AuthScreen(),
        TradingHubScreen.routeName: (ctx) => TradingHubScreen(),
        PoSWSimulationScreen.routeName: (ctx) => PoSWSimulationScreen(),
        EnergyMarketScreen.routeName: (ctx) => EnergyMarketScreen(),
        DemoMainHomeScreen.routeName: (ctx) => const DemoMainHomeScreen(),
        // Use the static routeName from your SolarProfileScreen class (defined in solar_profile.dart)
        SolarProfileScreen.routeName: (ctx) => const SolarProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}