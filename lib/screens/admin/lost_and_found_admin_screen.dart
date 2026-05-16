import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/lost_and_found_model.dart';
import '../../services/lost_and_found_service.dart';

class LostAndFoundAdminScreen extends StatefulWidget {
  const LostAndFoundAdminScreen({super.key});

  @override
  State<LostAndFoundAdminScreen> createState() =>
      _LostAndFoundAdminScreenState();
}

class _LostAndFoundAdminScreenState extends State<LostAndFoundAdminScreen> {
  final LostAndFoundService _service = LostAndFoundService();
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found - Admin'),
        actions: [
          DropdownButton<String>(
            value: _filter,
            dropdownColor: theme.colorScheme.surface,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'lost', child: Text('Lost')),
              DropdownMenuItem(value: 'found', child: Text('Found')),
              DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
            ],
            onChanged: (value) => setState(() => _filter = value!),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: StreamBuilder<List<LostAndFoundModel>>(
        stream: _service.getAllItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No items found!'));
          }

          final items = _filter == 'all'
              ? snapshot.data!
              : snapshot.data!
                  .where((i) => i.status == _filter)
                  .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.status == 'lost'
                                  ? Colors.red.shade100
                                  : item.status == 'found'
                                      ? Colors.green.shade100
                                      : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.status.toUpperCase(),
                              style: TextStyle(
                                color: item.status == 'lost'
                                    ? Colors.red
                                    : item.status == 'found'
                                        ? Colors.green
                                        : Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(item.description),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Text(item.location),
                          const SizedBox(width: 16),
                          const Icon(Icons.category, size: 16),
                          const SizedBox(width: 4),
                          Text(item.category),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Posted by: ${item.postedBy} • ${item.date}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Status Change Buttons
                          if (item.status != 'lost')
                            TextButton(
                              onPressed: () =>
                                  _service.updateStatus(item.id, 'lost'),
                              child: const Text('Mark Lost',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          if (item.status != 'found')
                            TextButton(
                              onPressed: () =>
                                  _service.updateStatus(item.id, 'found'),
                              child: const Text('Mark Found',
                                  style: TextStyle(color: Colors.green)),
                            ),
                          if (item.status != 'resolved')
                            TextButton(
                              onPressed: () =>
                                  _service.updateStatus(item.id, 'resolved'),
                              child: const Text('Resolve',
                                  style: TextStyle(color: Colors.blue)),
                            ),
                          const Spacer(),
                          // Delete Button
                          IconButton(
                            onPressed: () => _showDeleteDialog(context, item.id),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _service.deleteItem(itemId);
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    String selectedStatus = 'lost';
    String selectedCategory = 'Electronics';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Item',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Item Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'lost', child: Text('Lost')),
                        DropdownMenuItem(
                            value: 'found', child: Text('Found')),
                      ],
                      onChanged: (v) =>
                          setModalState(() => selectedStatus = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Electronics',
                            child: Text('Electronics')),
                        DropdownMenuItem(
                            value: 'Books', child: Text('Books')),
                        DropdownMenuItem(
                            value: 'Clothing', child: Text('Clothing')),
                        DropdownMenuItem(
                            value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) =>
                          setModalState(() => selectedCategory = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;
                    try {
                      await FirebaseFirestore.instance
                          .collection('lost_and_found')
                          .add({
                        'title': titleController.text,
                        'description': descController.text,
                        'category': selectedCategory,
                        'status': selectedStatus,
                        'location': locationController.text,
                        'date': DateTime.now().toString().split(' ')[0],
                        'postedBy': 'Admin',
                        'userId': 'admin',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Item added successfully!'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Add Item'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}