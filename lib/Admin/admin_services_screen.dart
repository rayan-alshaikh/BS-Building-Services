import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_ui.dart';

class AdminServicesScreen extends StatelessWidget {
  const AdminServicesScreen({super.key});

  static const String _colServices = 'services';

  void _go(BuildContext context, int i) {
    switch (i) {
      case 0:
        Navigator.pushReplacementNamed(context, '/admin');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/adminUsers');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/adminServices');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/adminCategories');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance.collection(_colServices);

    return AdminScaffold(
      title: 'Services',
      subtitle: 'Enable / Disable services',
      bottomNavIndex: 2,
      onBottomNavTap: (i) => _go(context, i),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No services found'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final id = doc.id;
              final data = doc.data();

              final title = (data['title'] ?? 'Untitled').toString();
              final category = (data['category'] ?? '').toString();
              final isActive = (data['isActive'] ?? true) == true;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (category.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              category,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Switch(
                      value: isActive,
                      onChanged: (v) async {
                        await FirebaseFirestore.instance
                            .collection(_colServices)
                            .doc(id)
                            .update({'isActive': v});
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
