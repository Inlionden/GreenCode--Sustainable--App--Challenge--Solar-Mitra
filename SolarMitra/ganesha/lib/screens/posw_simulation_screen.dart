// lib/screens/posw_simulation_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_profile.dart';
import '../services/user_session.dart'; // Import UserSession

class PoSWSimulationScreen extends StatefulWidget {
  static const routeName = '/posw-simulation';

  @override
  _PoSWSimulationScreenState createState() => _PoSWSimulationScreenState();
}

class _PoSWSimulationScreenState extends State<PoSWSimulationScreen> {
  final DatabaseReference _usersProfileRef = FirebaseDatabase.instance.ref('user_profiles');
  final _formKey = GlobalKey<FormState>();
  double _simulatedKWh = 0.0;
  bool _isProcessing = false;
  String? _loggedInUsername;
  UserProfile? _currentUserProfile; // To hold profile data including what's passed or fetched

 @override
  void initState() {
    super.initState();
    // Arguments are typically available after initState in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is UserProfile) {
      _currentUserProfile = args;
      _loggedInUsername = _currentUserProfile!.username; // Set username from passed profile
    } else {
      // Fallback: If no profile passed, try to get username from session and fetch
      _loadUsernameAndFetchProfile();
    }
  }

  Future<void> _loadUsernameAndFetchProfile() async {
    final username = await UserSession.getLoggedInUsername();
    if (username != null && mounted) {
      setState(() {
        _loggedInUsername = username;
      });
      await _fetchFreshProfile(username);
    }
  }

  Future<void> _fetchFreshProfile(String username) async {
      final snapshot = await _usersProfileRef.child(username).get();
      if (snapshot.exists && mounted) {
          setState(() {
              _currentUserProfile = UserProfile.fromSnapshot(snapshot);
          });
      }
  }

  Future<void> _submitSimulatedGeneration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    if (_loggedInUsername == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not identified! Please re-login.')));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      double poSWAwarded = _simulatedKWh * 0.1;

      await _usersProfileRef.child(_loggedInUsername!).runTransaction((Object? mutableData) {
        if (mutableData == null) {
          return Transaction.abort();
        }
        Map<String, dynamic> profileData = Map<String, dynamic>.from(mutableData as Map);

        double currentPoSW = (profileData['poSWScore'] as num?)?.toDouble() ?? 0.0;
        double currentEnergy = (profileData['energyBalanceKWh'] as num?)?.toDouble() ?? 0.0;

        profileData['poSWScore'] = currentPoSW + poSWAwarded;
        profileData['energyBalanceKWh'] = currentEnergy + _simulatedKWh;
        profileData['lastPoSWUpdate'] = ServerValue.timestamp;

        return Transaction.success(profileData);
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Successfully reported ${_simulatedKWh.toStringAsFixed(2)} kWh. PoSW updated!'),
        backgroundColor: Colors.green,
      ));
      _formKey.currentState?.reset();
       if(mounted) {
         setState(() {
            _simulatedKWh = 0.0;
            if (_currentUserProfile != null) { // Optimistically update local profile
                _currentUserProfile!.poSWScore += poSWAwarded;
                _currentUserProfile!.energyBalanceKWh += _simulatedKWh;
                _currentUserProfile!.lastPoSWUpdate = DateTime.now();
            }
         });
       }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating PoSW: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if(mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simulate Solar Generation'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Report Your Daily Solar Generation',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'This contributes to your PoSW score and adds to your tradable energy balance.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              if (_currentUserProfile != null)
                 Padding(
                   padding: const EdgeInsets.only(bottom: 15.0),
                   child: Card(
                     elevation: 2,
                     child: Padding(
                       padding: const EdgeInsets.all(12.0),
                       child: Text(
                          'Current PoSW: ${_currentUserProfile!.poSWScore.toStringAsFixed(2)}\nBalance: ${_currentUserProfile!.energyBalanceKWh.toStringAsFixed(2)} kWh',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                     ),
                   ),
                 )
              else if (_loggedInUsername != null) // Show loading or placeholder if profile is being fetched
                Padding(
                   padding: const EdgeInsets.only(bottom: 15.0),
                   child: Center(child: Text("Loading profile for $_loggedInUsername..."))
                ),


              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Energy Generated Today (kWh)',
                  hintText: 'e.g., 15.5',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.flash_on_outlined)
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter generated energy.';
                  }
                  final n = double.tryParse(value);
                  if (n == null || n <= 0) {
                    return 'Please enter a valid positive number.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _simulatedKWh = double.parse(value!);
                },
              ),
              SizedBox(height: 25),
              if (_isProcessing)
                Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  icon: Icon(Icons.send_outlined),
                  label: Text('Submit Generation', style: TextStyle(fontSize: 16)),
                  onPressed: _submitSimulatedGeneration,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}