import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_ui.dart';

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  static const String _colCategories = 'categories';

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

  Future<void> _addCategory(BuildContext context) async {
    final controller = TextEditingController();

    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    final name = controller.text.trim();
    controller.dispose();

    if (shouldAdd != true || name.isEmpty) return;

    await FirebaseFirestore.instance.collection(_colCategories).add({
      'name': name,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _editCategory(BuildContext context, String id, String currentName) async {
    final controller = TextEditingController(text: currentName);

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    final name = controller.text.trim();
    controller.dispose();

    if (shouldSave != true || name.isEmpty) return;

    await FirebaseFirestore.instance.collection(_colCategories).doc(id).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection(_colCategories)
        .orderBy('createdAt', descending: true);

    return AdminScaffold(
      title: 'Categories',
      subtitle: 'Add / Edit / Delete categories',
      bottomNavIndex: 3,
      onBottomNavTap: (i) => _go(context, i),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _addCategory(context),
          tooltip: 'Add category',
        ),
      ],
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Failed to load categories'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No categories found'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final id = doc.id;
              final data = doc.data();

              final name = (data['name'] ?? 'Untitled').toString();
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
                      child: InkWell(
                        onTap: () => _editCategory(context, id, name),
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Switch(
                      value: isActive,
                      onChanged: (v) async {
                        await FirebaseFirestore.instance
                            .collection(_colCategories)
                            .doc(id)
                            .update({
                          'isActive': v,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                      },
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editCategory(context, id, name),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Delete Category'),
                            content: Text('Are you sure you want to delete "$name"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(dialogContext, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection(_colCategories)
                              .doc(id)
                              .delete();
                        }
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
