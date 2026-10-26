import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RoleDecider extends StatelessWidget {
  const RoleDecider({super.key});

  static const String _colUsers = 'users';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection(_colUsers).doc(user.uid).get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Scaffold(
            body: Center(child: Text('Failed to load profile: ${snap.error}')),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('User profile not found')),
          );
        }

        final data = snap.data!.data() ?? <String, dynamic>{};
        final role = (data['role'] ?? 'customer').toString().toLowerCase();
        (data['status'] ?? '').toString().toLowerCase();
        final isDisabled = (data['isDisabled'] ?? false) == true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;

          if (isDisabled) {
            Navigator.pushReplacementNamed(context, '/login');
            return;
          }

          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else if (role == 'provider') {
            // Optional: if you want to block providers until approved
            // if (status != 'approved') {
            //   Navigator.pushReplacementNamed(context, '/login');
            //   return;
            // }
            Navigator.pushReplacementNamed(context, '/providerHome');
          } else {
            Navigator.pushReplacementNamed(context, '/customerHome');
          }
        });

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }
}
