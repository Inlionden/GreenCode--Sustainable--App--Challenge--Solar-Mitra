// lib/solar_profile/solar_profile_screening.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_profile.dart'; // Adjust path if needed
import '../services/user_session.dart';  // Adjust path if needed

class SolarProfileScreen extends StatefulWidget {
  static const routeName = '/solar-profile';
  const SolarProfileScreen({super.key});

  @override
  State<SolarProfileScreen> createState() => _SolarProfileScreenState();
}

class _SolarProfileScreenState extends State<SolarProfileScreen> {
  UserProfile? _currentUserProfile;
  String? _loggedInUsername;
  bool _isLoading = true;

  final DatabaseReference _usersProfileRef = FirebaseDatabase.instance.ref().child('user_profiles');

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    final usernameFromSession = await UserSession.getLoggedInUsername();
    if (usernameFromSession != null) {
      if (mounted) {
        setState(() {
          _loggedInUsername = usernameFromSession;
        });
      }
      if (_currentUserProfile == null) {
        await _fetchUserProfileFromDatabase(usernameFromSession);
      } else {
         if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentUserProfile == null && ModalRoute.of(context)?.settings.arguments != null) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is UserProfile) {
        if (mounted) {
          setState(() {
            _currentUserProfile = args;
            _loggedInUsername = _currentUserProfile?.username;
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _fetchUserProfileFromDatabase(String username) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final snapshot = await _usersProfileRef.child(username).get();
      if (snapshot.exists && snapshot.value != null && mounted) {
        setState(() {
          _currentUserProfile = UserProfile.fromSnapshot(snapshot);
          _isLoading = false;
        });
      } else if (mounted) {
        print("SolarProfileScreen: Profile not found in DB for $username");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("SolarProfileScreen: Error fetching profile for $username: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading profile data."), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Profile & Tools'),
        // Use the main app's theme for consistency when navigated to from there
        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_currentUserProfile != null)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                              "Profile for: ${_currentUserProfile!.username}",
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (_currentUserProfile!.email.isNotEmpty)
                              Text("Email: ${_currentUserProfile!.email}"),
                            Text("PoSW Score: ${_currentUserProfile!.poSWScore.toStringAsFixed(2)}"),
                            Text("Energy Balance: ${_currentUserProfile!.energyBalanceKWh.toStringAsFixed(2)} kWh"),
                          ],
                        ),
                      ),
                    )
                  else if (_loggedInUsername != null)
                     Padding(
                       padding: const EdgeInsets.only(bottom: 16.0),
                       child: Text(
                        "Displaying generic tools. User: $_loggedInUsername (Profile details not fully loaded).",
                         style: Theme.of(context).textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic),
                       ),
                     )
                  else
                     Padding(
                       padding: const EdgeInsets.only(bottom: 16.0),
                       child: Text(
                        "User not identified. Showing generic tools or example data.",
                         style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.orange.shade700),
                       ),
                     ),
                  const SizedBox(height: 20),
                  Text(
                    'Your Solar Setup Overview (Example)',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.solar_power, color: Colors.orange),
                    title: Text('Total Installed Capacity'),
                    subtitle: Text('5.5 kWp'),
                  ),
                  const Divider(height: 30),
                  Text(
                    'Standalone Solar Tools (Example)',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.calculate, color: Colors.blue),
                    title: Text('Savings Estimator'),
                    onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Savings Estimator Tool (To Be Implemented)')),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}