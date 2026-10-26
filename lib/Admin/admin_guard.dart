import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminGuard extends StatelessWidget {
  const AdminGuard({
    super.key,
    required this.child,
  });

  final Widget child;

  static const String _colUsers = 'users';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _Denied(message: 'You must sign in first.');
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(_colUsers)
          .doc(user.uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return const _Denied(message: 'User profile not found.');
        }

        final data = snap.data!.data() ?? <String, dynamic>{};
        final role = (data['role'] ?? '').toString();

        if (role != 'admin') {
          return const _Denied(message: 'Access denied (Admins only).');
        }

        return child;
      },
    );
  }
}

class _Denied extends StatelessWidget {
  const _Denied({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restricted')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
