import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_drawer.dart'; // ✅ تأكد المسار حسب مشروعك

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  static const String _colUsers = 'users';
  static const String _colProvidersPublic = 'providers_public';

  static const Color _blueDark = Color(0xFF0B2E5E);
  static const Color _bgLight = Color(0xFFF4F6FA);

  // ===== Helpers (SAFE for null + any type) =====
  static String _s(dynamic v) => (v ?? '').toString().trim();

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static bool _isApprovedFrom(Map<String, dynamic> data) {
    final approvedField = data['approved'];
    final statusStr = _s(data['status']).toLowerCase();

    if (approvedField is bool) return approvedField;
    return statusStr == 'approved' || statusStr == 'active';
  }

  static String _pickName(Map<String, dynamic> data) {
    final n = _s(data['name']);
    if (n.isNotEmpty) return n;

    final f = _s(data['fullName']);
    if (f.isNotEmpty) return f;

    final d = _s(data['displayName']);
    if (d.isNotEmpty) return d;

    return '';
  }

  static String _pickCity(Map<String, dynamic> data) {
    final c = _s(data['city']);
    if (c.isNotEmpty) return c;

    final l = _s(data['location']);
    if (l.isNotEmpty) return l;

    return '';
  }

  static String _pickLocation(Map<String, dynamic> data) {
    final l = _s(data['location']);
    if (l.isNotEmpty) return l;

    final c = _s(data['city']);
    if (c.isNotEmpty) return c;

    return '';
  }

  /// ✅ عند الموافقة/الرفض:
  /// - يحدث users/{uid} (approved + status)
  /// - لو كان role=provider: يعمل upsert لـ providers_public/{uid} ويضع status + isActive
  static Future<void> _setApproval({
    required String uid,
    required Map<String, dynamic> userData,
    required bool approve,
  }) async {
    final db = FirebaseFirestore.instance;

    final userRef = db.collection(_colUsers).doc(uid);
    final providerRef = db.collection(_colProvidersPublic).doc(uid);

    final role = _s(userData['role']).toLowerCase();
    final isProvider = role == 'provider';

    final batch = db.batch();

    // 1) Update user doc
    batch.set(
      userRef,
      {
        'approved': approve,
        'status': approve ? 'approved' : 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // 2) If provider -> sync providers_public
    if (isProvider) {
      final name = _pickName(userData);
      final email = _s(userData['email']);
      final phone = _s(userData['phone']);
      final city = _pickCity(userData);
      final location = _pickLocation(userData);
      final profession = _s(userData['profession']);
      final providerType = _s(userData['providerType']);
      final photoUrl = _s(userData['photoUrl']);

      final avgRating = _toDouble(userData['avgRating']);
      final ratingCount = _toInt(userData['ratingCount']);
      final ratingSum = _toDouble(userData['ratingSum']);

      batch.set(
        providerRef,
        {
          // identifiers
          'userId': uid,
          'uid': uid,

          // profile
          if (name.isNotEmpty) 'name': name,
          if (email.isNotEmpty) 'email': email,
          if (phone.isNotEmpty) 'phone': phone,
          if (city.isNotEmpty) 'city': city,
          if (location.isNotEmpty) 'location': location,
          if (profession.isNotEmpty) 'profession': profession,
          if (providerType.isNotEmpty) 'providerType': providerType,
          if (photoUrl.isNotEmpty) 'photoUrl': photoUrl,

          // rating
          'avgRating': avgRating,
          'ratingCount': ratingCount,
          'ratingSum': ratingSum,

          // moderation
          'status': approve ? 'approved' : 'pending',
          'isActive': approve, // ✅ الليست عندك بتفلتر isActive=true
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance.collection(_colUsers);

    return Scaffold(
      backgroundColor: _bgLight,

      // ✅ ربط Admin Drawer
      drawer: const AdminDrawer(selectedRoute: '/adminUsers'),

      appBar: AppBar(
        backgroundColor: _blueDark,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: usersRef.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();

              final name = _pickName(data);
              final email = _s(data['email']);
              final phone = _s(data['phone']);
              final role = _s(data['role']).isEmpty ? 'customer' : _s(data['role']);
              final statusStr = _s(data['status']);
              final cityOrLocation = _pickLocation(data);

              final isApproved = _isApprovedFrom(data);

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  title: Text(name.isEmpty ? doc.id : name),
                  subtitle: Text(
                    [
                      if (email.isNotEmpty) email,
                      if (phone.isNotEmpty) 'Phone: $phone',
                      if (cityOrLocation.isNotEmpty) 'City: $cityOrLocation',
                      'Role: $role',
                      'Status: ${statusStr.isEmpty ? (isApproved ? "approved" : "pending") : statusStr}',
                    ].join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Switch(
                    value: isApproved,
                    onChanged: (v) async {
                      try {
                        await _setApproval(
                          uid: doc.id,
                          userData: data,
                          approve: v,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(v ? 'Approved' : 'Set to pending'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      } on FirebaseException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Firestore error: ${e.code}')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
