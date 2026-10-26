import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({
    super.key,
    required this.selectedRoute,
  });

  final String selectedRoute;

  static const String _colUsers = 'users';

  bool _isSelected(BuildContext context, String route) {
    final current = ModalRoute.of(context)?.settings.name;
    return selectedRoute == route || current == route;
  }

  void _go(BuildContext context, String route) {
    Navigator.pop(context); // close drawer
    if (_isSelected(context, route)) return;
    Navigator.pushReplacementNamed(context, route);
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.pop(context);
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header (same style) + admin name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.blueDark, AppColors.blueMid],
                ),
              ),
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: (uid == null)
                    ? null
                    : FirebaseFirestore.instance
                        .collection(_colUsers)
                        .doc(uid)
                        .snapshots(),
                builder: (context, snap) {
                  final data = snap.data?.data();
                  final name = (data?['name'] ?? 'Admin').toString();
                  final email = (data?['email'] ?? '').toString();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: AppColors.blueDark,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'Control Panel',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            _tile(
              context,
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              route: '/admin',
            ),
            _tile(
              context,
              icon: Icons.people_outline,
              label: 'Users',
              route: '/adminUsers',
            ),
            _tile(
              context,
              icon: Icons.handyman_outlined,
              label: 'Services',
              route: '/adminServices',
            ),
            _tile(
              context,
              icon: Icons.category_outlined,
              label: 'Categories',
              route: '/adminCategories',
            ),

            const Spacer(),
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final selected = _isSelected(context, route);

    final fg = selected ? AppColors.blueDark : Colors.black.withOpacity(0.75);
    final bg =
        selected ? AppColors.blueDark.withOpacity(0.10) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.blueDark.withOpacity(0.25)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: fg),
        title: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
        onTap: () => _go(context, route),
      ),
    );
  }
}
