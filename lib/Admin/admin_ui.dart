import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// AdminScaffold compatible with legacy pages + Drawer
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.selectedRoute,
    this.bottomNavIndex,
    this.onBottomNavTap,
    this.actions,
  });

  final String title;
  final String subtitle;
  final Widget body;

  /// Selected item inside the drawer.
  /// If not passed, current route will be used automatically.
  final String? selectedRoute;

  /// Legacy params (kept to avoid breaking old pages)
  final int? bottomNavIndex;
  final ValueChanged<int>? onBottomNavTap;

  final List<Widget>? actions;

  String _currentRoute(BuildContext context) {
    final r = ModalRoute.of(context)?.settings.name;
    return selectedRoute ?? r ?? '/admin';
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentRoute(context);

    return Scaffold(
      backgroundColor: AppColors.bgLight,

      /// Drawer (instead of BottomNav)
      drawer: AdminDrawer(currentRoute: current),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: actions,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),

        /// App gradient
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.blueDark, AppColors.blueMid],
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: body,
        ),
      ),
    );
  }
}

/// ---------------------------
/// ADMIN DRAWER
/// ---------------------------
class AdminDrawer extends StatelessWidget {
  const AdminDrawer({
    super.key,
    required this.currentRoute,
  });

  final String currentRoute;


  bool _selected(String route) => currentRoute == route;

  void _go(BuildContext context, String route) {
    Navigator.pop(context);
    if (_selected(route)) return;
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
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _DrawerHeader(uid: uid),

            const SizedBox(height: 6),

            _DrawerTile(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              selected: _selected('/admin'),
              onTap: () => _go(context, '/admin'),
            ),
            _DrawerTile(
              icon: Icons.people_outline,
              label: 'Users',
              selected: _selected('/adminUsers'),
              onTap: () => _go(context, '/adminUsers'),
            ),
            _DrawerTile(
              icon: Icons.handyman_outlined,
              label: 'Services',
              selected: _selected('/adminServices'),
              onTap: () => _go(context, '/adminServices'),
            ),
            _DrawerTile(
              icon: Icons.category_outlined,
              label: 'Categories',
              selected: _selected('/adminCategories'),
              onTap: () => _go(context, '/adminCategories'),
            ),

            const SizedBox(height: 12),
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
}

/// Header: admin name + email + app colors
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.uid});

  final String? uid;

  static const String _colUsers = 'users';

  @override
  Widget build(BuildContext context) {
    return Container(
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
            : FirebaseFirestore.instance.collection(_colUsers).doc(uid).snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data();
          final name = (data?['name'] ?? 'Admin').toString();
          final email = (data?['email'] ?? '').toString();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.blueDark,
                  size: 28,
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
              const SizedBox(height: 4),
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
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.blueDark : Colors.black.withOpacity(0.75);
    final bg = selected ? AppColors.blueDark.withOpacity(0.10) : Colors.transparent;

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
        onTap: onTap,
      ),
    );
  }
}
