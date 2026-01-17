// lib/solar_profile/solar_profile_screen.dart
import 'package:flutter/material.dart';
import '../models/user_profile.dart'; // Assuming you might want to show user info
import '../services/user_session.dart'; // To get current user if needed

class SolarProfileScreen extends StatefulWidget {
  static const routeName = '/solar-profile';
  const SolarProfileScreen({super.key});

  @override
  State<SolarProfileScreen> createState() => _SolarProfileScreenState();
}

class _SolarProfileScreenState extends State<SolarProfileScreen> {
  UserProfile? _currentUserProfile; // From arguments or fetched
  String? _loggedInUsername;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // If you pass UserProfile as argument, it will be caught in didChangeDependencies
    // Otherwise, we load it here based on session
    _loadData();
  }

  Future<void> _loadData() async {
    final username = await UserSession.getLoggedInUsername();
    if (username != null && mounted) {
      setState(() {
        _loggedInUsername = username;
      });
      // Here you would typically fetch more detailed solar setup data for this user
      // For now, we'll just use the basic UserProfile if available or passed.
      // If UserProfile is passed as an argument, it will be handled in didChangeDependencies
    }
     if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is UserProfile) {
      if (mounted) {
        setState(() {
          _currentUserProfile = args;
          _loggedInUsername = _currentUserProfile?.username;
          _isLoading = false;
        });
      }
    } else if (_loggedInUsername == null && _isLoading) { // If not passed and not yet loaded
      _loadData(); // Attempt to load via session
    } else if (_loggedInUsername != null && _isLoading && _currentUserProfile == null){
      // Username loaded from session, but profile not yet loaded or passed
      // You might want to fetch the UserProfile here if it's critical for this screen
      // For simplicity, this placeholder assumes it might be passed or uses username
       if (mounted) {
         setState(() {
           _isLoading = false;
         });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Profile & Tools'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                            Text("Email: ${_currentUserProfile!.email}"),
                            Text("PoSW Score: ${_currentUserProfile!.poSWScore.toStringAsFixed(2)}"),
                          ],
                        ),
                      ),
                    )
                  else if (_loggedInUsername != null)
                     Text(
                      "Displaying tools for user: $_loggedInUsername",
                       style: Theme.of(context).textTheme.titleMedium,
                    )
                  else
                     Text(
                      "User not identified. Some features may be limited.",
                       style: Theme.of(context).textTheme.titleMedium,
                    ),

                  const SizedBox(height: 20),
                  Text(
                    'Your Solar Setup Overview',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  // --- Placeholder for your Solar Profile content ---
                  // Example: Display total installed capacity (would come from your panel management)
                  // Example: Link to rooftop panel configuration (could navigate back or to a sub-screen)
                  ListTile(
                    leading: Icon(Icons.solar_power, color: Colors.orange),
                    title: Text('Total Installed Capacity'),
                    subtitle: Text('5.5 kWp (Example)'), // Replace with dynamic data
                  ),
                  ListTile(
                    leading: Icon(Icons.roofing, color: Colors.brown),
                    title: Text('Rooftop Sections'),
                    subtitle: Text('2 sections configured (Example)'),
                    onTap: () {
                      // Potentially navigate to a screen that shows the RooftopManagementScreen
                      // or a summary of it. This requires more complex navigation setup.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Panel configuration view (To be implemented)')),
                      );
                    },
                  ),
                  const Divider(height: 30),
                  Text(
                    'Standalone Solar Tools',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.calculate, color: Colors.blue),
                    title: Text('Savings Estimator'),
                    onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Savings Estimator Tool (To be implemented)')),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.sunny, color: Colors.yellow.shade700),
                    title: Text('Optimal Angle Calculator'),
                     onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Angle Calculator Tool (To be implemented)')),
                      );
                    },
                  ),
                  // ... Add more of your specific Solar Profile tools and displays here
                  // --- End Placeholder ---
                ],
              ),
            ),
    );
  }
}