// lib/models/user_profile.dart
import 'package:firebase_database/firebase_database.dart';

class UserProfile {
  final String username; // Username is the primary key conceptually
  final String email;
  double poSWScore;
  double energyBalanceKWh;
  final DateTime createdAt;
  DateTime? lastPoSWUpdate;

  UserProfile({
    required this.username,
    required this.email,
    this.poSWScore = 0.0,
    this.energyBalanceKWh = 0.0,
    required this.createdAt,
    this.lastPoSWUpdate,
  });

  factory UserProfile.fromSnapshot(DataSnapshot snapshot) {
    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    return UserProfile(
      username: snapshot.key!, // Username is the key
      email: data['email'] as String? ?? '', // Handle potential null email
      poSWScore: (data['poSWScore'] as num?)?.toDouble() ?? 0.0,
      energyBalanceKWh: (data['energyBalanceKWh'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      lastPoSWUpdate: data['lastPoSWUpdate'] != null && data['lastPoSWUpdate'] is int
          ? DateTime.fromMillisecondsSinceEpoch(data['lastPoSWUpdate'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'poSWScore': poSWScore,
        'energyBalanceKWh': energyBalanceKWh,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'lastPoSWUpdate': lastPoSWUpdate?.millisecondsSinceEpoch,
      };
}