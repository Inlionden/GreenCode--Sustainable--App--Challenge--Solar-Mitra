// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert'; // For utf8 encoding
import 'package:crypto/crypto.dart'; // For SHA256 hashing (DEMONSTRATION ONLY)

import 'trading_hub_screen.dart';
import '../services/user_session.dart'; // Import UserSession

class AuthScreen extends StatefulWidget {
  static const routeName = '/auth';

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final DatabaseReference _credentialsRef = FirebaseDatabase.instance.ref().child('user_credentials');
  final DatabaseReference _usersProfileRef = FirebaseDatabase.instance.ref().child('user_profiles');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  String? _errorMessage;

  String _hashPassword(String password) {
    var bytes = utf8.encode(password + "SolarMitraSaltDemo"); // Basic "salting" - still not secure
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      _usernameController.clear();
    });
  }

  Future<void> _submitAuthForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final String enteredUsername = _usernameController.text.trim();
    final String enteredPassword = _passwordController.text.trim();
    final String enteredEmail = _emailController.text.trim();

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      if (_isLoginMode) {
        // --- Login Logic (Custom) ---
        final credentialSnapshot = await _credentialsRef.child(enteredUsername).get();
        if (!credentialSnapshot.exists || credentialSnapshot.value == null) {
          throw Exception('Username not found.');
        }
        final storedHashedPassword = credentialSnapshot.value as String;
        final String hashedEnteredPassword = _hashPassword(enteredPassword);

        if (hashedEnteredPassword == storedHashedPassword) {
          // Passwords match - "Login" successful
          await UserSession.loginUser(enteredUsername); // Store username in session
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(TradingHubScreen.routeName);
          }
        } else {
          throw Exception('Incorrect password.');
        }
      } else {
        // --- Registration Logic (Custom) ---
        final credentialSnapshot = await _credentialsRef.child(enteredUsername).get();
        if (credentialSnapshot.exists) {
          throw Exception('Username already exists. Please choose another.');
        }

        final String hashedPasswordToStore = _hashPassword(enteredPassword);
        // Store credentials
        await _credentialsRef.child(enteredUsername).set(hashedPasswordToStore);

        // Store user profile
        await _usersProfileRef.child(enteredUsername).set({
          'email': enteredEmail, // Username is the key
          'poSWScore': 0.0,
          'energyBalanceKWh': 0.0,
          'createdAt': ServerValue.timestamp,
          'lastPoSWUpdate': null,
        });

        await UserSession.loginUser(enteredUsername); // Auto-login after registration
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(TradingHubScreen.routeName);
        }
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst("Exception: ", ""); // Clean up error message
       print("Auth Error: $_errorMessage");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

 @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? 'Login (Custom)' : 'Register (Custom)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      _isLoginMode ? 'Welcome Back!' : 'Create Your Account',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 25),
                    TextFormField( // Username field is always needed
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length < 3) {
                          return 'Username must be at least 3 characters.';
                        }
                        if (value.contains('.') || value.contains('#') || value.contains('\$') || value.contains('[') || value.contains(']')) {
                          return 'Username cannot contain ., #, \$, [, or ]'; // Firebase key restrictions
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    if (!_isLoginMode) // Email only for registration for profile
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address (Optional)',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) { // Make email optional during registration
                          if (value != null && value.isNotEmpty && (!value.contains('@') || !value.contains('.'))) {
                            return 'Please enter a valid email address or leave blank.';
                          }
                          return null;
                        },
                      ),
                    if (!_isLoginMode) SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 25),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (_isLoading)
                      Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton(
                        onPressed: _submitAuthForm,
                        child: Text(_isLoginMode ? 'Login' : 'Register', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    SizedBox(height: 15),
                    TextButton(
                      onPressed: _toggleMode,
                      child: Text(
                        _isLoginMode ? 'Don\'t have an account? Register' : 'Already have an account? Login',
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}