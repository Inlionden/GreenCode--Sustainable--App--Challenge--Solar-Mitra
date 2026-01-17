// lib/screens/trading_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Keep for UserProfile
import '../models/user_profile.dart'; // Keep for UserProfile
import 'posw_simulation_screen.dart';
import 'energy_market_screen.dart';
import 'auth_screen.dart';
import 'demo_main_home_screen.dart';
import '../services/user_session.dart';
// <<< UPDATE THIS IMPORT >>>
import '../solar_profile/solar_profile.dart'; // Assuming SolarProfileScreen class is in this file

class TradingHubScreen extends StatefulWidget {
  static const routeName = '/trading-hub';
  @override
  _TradingHubScreenState createState() => _TradingHubScreenState();
}

class _TradingHubScreenState extends State<TradingHubScreen> {
  DatabaseReference? _userProfileRef;
  UserProfile? _currentUserProfile;
  String? _loggedInUsername;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessionAndProfile();
  }

  Future<void> _loadSessionAndProfile() async {
    final username = await UserSession.getLoggedInUsername();
    if (username != null && mounted) {
      setState(() {
        _loggedInUsername = username;
        _userProfileRef = FirebaseDatabase.instance.ref('user_profiles/$username');
      });
      _fetchUserProfile();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AuthScreen.routeName);
        }
      });
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fetchUserProfile() {
     _userProfileRef?.onValue.listen((DatabaseEvent event) {
      if (mounted && event.snapshot.exists) {
        final value = event.snapshot.value;
        if (value != null && value is Map) {
            setState(() {
              _currentUserProfile = UserProfile.fromSnapshot(event.snapshot);
              _isLoading = false;
            });
        } else if (mounted) {
             setState(() {
                _isLoading = false;
                print("User profile data is not in the expected format for username: $_loggedInUsername");
             });
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          print("User profile not found for username: $_loggedInUsername");
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error fetching profile: $error"), backgroundColor: Colors.red));
      }
    });
  }

  Future<void> _logout() async {
    await UserSession.logoutUser();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AuthScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SolarMitra Hub'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_applications_outlined),
            tooltip: 'Solar Profile & Tools',
            onPressed: () {
              // This version of SolarProfileScreen (from solar_profile.dart)
              // is a simple tool navigator and doesn't expect UserProfile argument.
              Navigator.of(context).pushNamed(SolarProfileScreen.routeName);
            },
          ),
          IconButton(
            icon: Icon(Icons.explore_outlined),
            tooltip: 'Go to Demo Section',
            onPressed: () {
              Navigator.of(context).pushNamed(DemoMainHomeScreen.routeName);
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _currentUserProfile == null || _loggedInUsername == null
              ? Center( /* ... error/loading UI ... */ )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (_currentUserProfile != null) _buildProfileCard(), // Check for null
                      SizedBox(height: 20),
                      _buildNavigationButton(
                        context,
                        icon: Icons.solar_power_outlined,
                        label: 'Simulate Solar Generation (PoSW)',
                        routeName: PoSWSimulationScreen.routeName,
                      ),
                      SizedBox(height: 12),
                      _buildNavigationButton(
                        context,
                        icon: Icons.storefront_outlined,
                        label: 'Energy Market',
                        routeName: EnergyMarketScreen.routeName,
                      ),
                    ],
                  ),
                ),
    );
  }

 Widget _buildProfileCard() {
    if (_currentUserProfile == null) return SizedBox.shrink(); // Should not happen if body is conditional
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${_currentUserProfile!.username}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Divider(),
            SizedBox(height: 10),
            if (_currentUserProfile!.email.isNotEmpty) _infoRow('Email:', _currentUserProfile!.email),
            _infoRow('PoSW Score:', _currentUserProfile!.poSWScore.toStringAsFixed(2), isHighlight: true),
            _infoRow('Energy Balance:', '${_currentUserProfile!.energyBalanceKWh.toStringAsFixed(2)} kWh', isHighlight: true),
            _infoRow('Member Since:', '${_currentUserProfile!.createdAt.toLocal().toString().substring(0, 10)}'),
             if(_currentUserProfile!.lastPoSWUpdate != null)
               _infoRow('Last PoSW Update:', '${_currentUserProfile!.lastPoSWUpdate!.toLocal().toString().substring(0, 16)}'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isHighlight ? 16 : 15,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(BuildContext context, {required IconData icon, required String label, required String routeName}) {
     return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(label, style: TextStyle(fontSize: 16)),
      ),
      onPressed: () {
        // The SolarProfileScreen from solar_profile.dart doesn't expect UserProfile args
        // So, if navigating there, we don't need to pass _currentUserProfile unless it's adapted
        if (routeName == SolarProfileScreen.routeName) {
            Navigator.of(context).pushNamed(routeName);
        } else if (_currentUserProfile != null) { // For other screens that might need it
          Navigator.of(context).pushNamed(routeName, arguments: _currentUserProfile);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile not loaded yet. Cannot navigate."), backgroundColor: Colors.orange),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}