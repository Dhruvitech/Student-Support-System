
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/lost_and_found_model.dart';
import '../../services/lost_and_found_service.dart';
import 'dart:typed_data';

class LostAndFoundAdminScreen extends StatefulWidget {
  const LostAndFoundAdminScreen({super.key});

  @override
  State<LostAndFoundAdminScreen> createState() =>
      _LostAndFoundAdminScreenState();
}

class _LostAndFoundAdminScreenState extends State<LostAndFoundAdminScreen> {
  final LostAndFoundService _service = LostAndFoundService();
  String _filter = 'all';
  final String _currentUserId =
      FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
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
              : snapshot.data!.where((i) => i.status == _filter).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final bool isOwner = item.userId == _currentUserId;
              final bool isResolved = item.status == 'resolved';

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

                      // ── Title + Status Badge ──
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

                      // ── Photo (shown if uploaded) ──
                      if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            item.imageUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                height: 180,
                                color: Colors.grey.shade100,
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 60,
                              color: Colors.grey.shade100,
                              child: const Center(
                                  child: Icon(Icons.broken_image,
                                      color: Colors.grey)),
                            ),
                          ),
                        ),
                      if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                        const SizedBox(height: 8),

                      // ── Description ──
                      Text(item.description),
                      const SizedBox(height: 8),

                      // ── Location + Category ──
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

                      // ── Posted by + Date ──
                      Text(
                        'Posted by: ${item.postedBy} • ${item.date}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),

                      // ── Contact Number ──
                      if (item.contactNumber.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.phone,
                                size: 16, color: Colors.teal),
                            const SizedBox(width: 4),
                            Text(
                              'Contact: ${item.contactNumber}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.teal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 12),

                      // ── Action Buttons ──
                      // ✅ Rule 1: resolved → no Mark Lost/Found buttons at all
                      // ✅ Rule 2: only owner sees buttons
                      // ✅ Rule 3: owner can still delete even after resolved
                      if (isOwner && !isResolved)
                        Row(
                          children: [
                            
                           
                            TextButton(
                              onPressed: () =>
                                  _service.updateStatus(item.id, 'resolved'),
                              child: const Text('Resolve',
                                  style: TextStyle(color: Colors.blue)),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () =>
                                  _showDeleteDialog(context, item.id),
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                            ),
                          ],
                        ),

                      // ✅ After resolved: only show label + delete, no other buttons
                      if (isOwner && isResolved)
                        Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.blue, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Marked as resolved',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () =>
                                  _showDeleteDialog(context, item.id),
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
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

  // ─────────────────────────────────────────────────────
  // Delete Dialog
  // ─────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────
  // Add Item Dialog (with photo upload)
  // ─────────────────────────────────────────────────────
  void _showAddItemDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    final contactController = TextEditingController();
    String selectedStatus = 'lost';
    String selectedCategory = 'Electronics';
    XFile? pickedImage;
    Uint8List? pickedImageBytes;
    bool isUploading = false;

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Item',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
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

                TextField(
                  controller: contactController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Photo Picker ──
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('Take a Photo'),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final img = await picker.pickImage(
                                source: ImageSource.camera,
                                imageQuality: 70,
                                );
                                if (img != null) {
                                final bytes = await img.readAsBytes();
                                setModalState(() {
                                pickedImage = img;
                                pickedImageBytes = bytes;
                                 });
                               }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Choose from Gallery'),
                              onTap: () async {
                                Navigator.pop(ctx);
                               final img = await picker.pickImage(
  source: ImageSource.gallery,
  imageQuality: 70,
);
if (img != null) {
  final bytes = await img.readAsBytes();
  setModalState(() {
    pickedImage = img;
    pickedImageBytes = bytes;
  });
}
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: pickedImageBytes != null ? 160 : 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                   child: pickedImageBytes != null
                   ? ClipRRect(
                   borderRadius: BorderRadius.circular(12),
                   child: Image.memory(
                   pickedImageBytes!,
                   fit: BoxFit.cover,
                   ),
                     )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  color: Colors.grey, size: 28),
                              SizedBox(height: 6),
                              Text('Add Photo (optional)',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
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
                    onPressed: isUploading
                        ? null
                        : () async {
                            if (titleController.text.isEmpty) return;
                            setModalState(() => isUploading = true);
                            try {
                              // ── Upload photo if selected ──
                              String imageUrl = '';
                            if (pickedImage != null && pickedImageBytes != null) {
  final ref = FirebaseStorage.instance
      .ref()
      .child('lost_and_found')
      .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
  await ref.putData(pickedImageBytes!);  // ← putData works on web
  imageUrl = await ref.getDownloadURL();
}

                              // ── Save to Firestore ──
                              await FirebaseFirestore.instance
                                  .collection('lost_and_found')
                                  .add({
                                'title': titleController.text,
                                'description': descController.text,
                                'category': selectedCategory,
                                'status': selectedStatus,
                                'location': locationController.text,
                                'date': DateTime.now()
                                    .toString()
                                    .split(' ')[0],
                                'postedBy': FirebaseAuth.instance
                                        .currentUser?.displayName ??
                                    'User',
                                'userId':
                                    FirebaseAuth.instance.currentUser?.uid ??
                                        '',
                                'contactNumber': contactController.text,
                                'imageUrl': imageUrl, // ✅ photo URL saved
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('✅ Item added successfully!'),
                                ),
                              );
                            } catch (e) {
                              setModalState(() => isUploading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: isUploading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                ),
                                SizedBox(width: 10),
                                Text('Uploading...'),
                              ],
                            )
                          : const Text('Add Item'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}