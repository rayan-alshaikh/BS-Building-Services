import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_ui.dart';
import '../theme/app_theme.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Admin Panel',
      subtitle: 'Control Panel',
      body: ListView(
        children: const [
          _QuickStatsCard(),
          SizedBox(height: 14),
          _LatestUsersCard(),
          SizedBox(height: 14),
          _LatestServicesCard(),
          SizedBox(height: 14),
          _LatestCategoriesCard(),
        ],
      ),
    );
  }
}

/// ============================
/// QUICK STATS + CHART
/// ============================
class _QuickStatsCard extends StatelessWidget {
  const _QuickStatsCard();

  static const String _colUsers = 'users';
  static const String _colServices = 'services';
  static const String _colCategories = 'categories';

  @override
  Widget build(BuildContext context) {
    final usersStream = FirebaseFirestore.instance.collection(_colUsers).snapshots();
    final servicesStream =
        FirebaseFirestore.instance.collection(_colServices).snapshots();
    final categoriesStream =
        FirebaseFirestore.instance.collection(_colCategories).snapshots();

    return _SectionCard(
      title: 'Quick Stats',
      subtitle: 'App status (Active / Inactive)',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: usersStream,
        builder: (context, usersSnap) {
          if (!usersSnap.hasData) return const _LoadingMini();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: servicesStream,
            builder: (context, servicesSnap) {
              if (!servicesSnap.hasData) return const _LoadingMini();

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: categoriesStream,
                builder: (context, catSnap) {
                  if (!catSnap.hasData) return const _LoadingMini();

                  final users = usersSnap.data!.docs.map((d) => d.data()).toList();
                  final services =
                      servicesSnap.data!.docs.map((d) => d.data()).toList();
                  final categories =
                      catSnap.data!.docs.map((d) => d.data()).toList();

                  int usersEnabled = 0, usersDisabled = 0;
                  for (final u in users) {
                    final dis = (u['isDisabled'] ?? false) == true;
                    if (dis) {
                      usersDisabled++;
                    } else {
                      usersEnabled++;
                    }
                  }

                  int servicesActive = 0, servicesInactive = 0;
                  for (final s in services) {
                    final active = (s['isActive'] ?? true) == true;
                    if (active) {
                      servicesActive++;
                    } else {
                      servicesInactive++;
                    }
                  }

                  int catsActive = 0, catsInactive = 0;
                  for (final c in categories) {
                    final active = (c['isActive'] ?? true) == true;
                    if (active) {
                      catsActive++;
                    } else {
                      catsInactive++;
                    }
                  }

                  final chartItems = <_BarItem>[
                    _BarItem('Users\nActive', usersEnabled.toDouble()),
                    _BarItem('Users\nDisabled', usersDisabled.toDouble()),
                    _BarItem('Services\nActive', servicesActive.toDouble()),
                    _BarItem('Services\nInactive', servicesInactive.toDouble()),
                    _BarItem('Categories\nActive', catsActive.toDouble()),
                    _BarItem('Categories\nInactive', catsInactive.toDouble()),
                  ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _MiniStat(
                            label: 'Users',
                            value: (usersEnabled + usersDisabled).toString(),
                          ),
                          _MiniStat(
                            label: 'Services',
                            value: (servicesActive + servicesInactive).toString(),
                          ),
                          _MiniStat(
                            label: 'Categories',
                            value: (catsActive + catsInactive).toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SimpleBarChart(items: chartItems),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.blueDark,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _BarItem {
  final String label;
  final double value;
  _BarItem(this.label, this.value);
}

class _SimpleBarChart extends StatelessWidget {
  const _SimpleBarChart({required this.items});

  final List<_BarItem> items;

  @override
  Widget build(BuildContext context) {
    final maxV =
        items.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b);
    final safeMax = maxV <= 0 ? 1.0 : maxV;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: SizedBox(
        height: 170,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, i) {
            final it = items[i];
            final h = (it.value / safeMax).clamp(0.0, 1.0);

            return SizedBox(
              width: 80,
              child: Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        height: 140 * h,
                        width: 18,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.blueMid, AppColors.blueDark],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    it.value.toInt().toString(),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    it.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ============================
/// LATEST 3 USERS
/// ============================
class _LatestUsersCard extends StatelessWidget {
  const _LatestUsersCard();

  static const String _colUsers = 'users';

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection(_colUsers)
        .orderBy('createdAt', descending: true)
        .limit(3);

    return _SectionCard(
      title: 'Users',
      subtitle: 'Latest 3 users',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const _LoadingMini();
          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return Text(
              'No users found',
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            );
          }

          return Column(
            children: docs.map((d) {
              final data = d.data();
              final name = (data['name'] ?? 'Unnamed').toString();
              final email = (data['email'] ?? '').toString();
              final role = (data['role'] ?? 'customer').toString();
              final isDisabled = (data['isDisabled'] ?? false) == true;

              return _RowTile(
                title: name,
                subtitle: email.isEmpty ? role : '$role • $email',
                trailing: isDisabled ? 'Disabled' : 'Active',
                trailingColor: isDisabled ? Colors.red : Colors.green,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/// ============================
/// LATEST 3 SERVICES
/// ============================
class _LatestServicesCard extends StatelessWidget {
  const _LatestServicesCard();

  static const String _colServices = 'services';

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection(_colServices)
        .orderBy('createdAt', descending: true)
        .limit(3);

    return _SectionCard(
      title: 'Services',
      subtitle: 'Latest 3 services',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const _LoadingMini();
          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return Text(
              'No services found',
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            );
          }

          return Column(
            children: docs.map((d) {
              final data = d.data();
              final title = (data['title'] ?? 'Untitled').toString();
              final category = (data['category'] ?? '').toString();
              final isActive = (data['isActive'] ?? true) == true;

              return _RowTile(
                title: title,
                subtitle: category.isEmpty ? '—' : category,
                trailing: isActive ? 'Active' : 'Inactive',
                trailingColor: isActive ? Colors.green : Colors.red,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/// ============================
/// LATEST 3 CATEGORIES
/// ============================
class _LatestCategoriesCard extends StatelessWidget {
  const _LatestCategoriesCard();

  static const String _colCategories = 'categories';

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection(_colCategories)
        .orderBy('createdAt', descending: true)
        .limit(3);

    return _SectionCard(
      title: 'Categories',
      subtitle: 'Latest 3 categories',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const _LoadingMini();
          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return Text(
              'No categories found',
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            );
          }

          return Column(
            children: docs.map((d) {
              final data = d.data();
              final name = (data['name'] ?? 'Unnamed').toString();
              final isActive = (data['isActive'] ?? true) == true;

              return _RowTile(
                title: name,
                subtitle: '—',
                trailing: isActive ? 'Active' : 'Inactive',
                trailingColor: isActive ? Colors.green : Colors.red,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/// ============================
/// UI HELPERS
/// ============================
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.black.withOpacity(0.55))),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: trailingColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: trailingColor.withOpacity(0.25)),
            ),
            child: Text(
              trailing,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: trailingColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingMini extends StatelessWidget {
  const _LoadingMini();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 60,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
