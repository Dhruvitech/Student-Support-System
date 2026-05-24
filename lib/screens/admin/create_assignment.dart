import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studentsupportsystem/screens/admin/view_submissions.dart';

class CreateAssignmentScreen extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assignments")),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getAssignments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No assignments found"));
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;
              DateTime deadline = (data['deadline'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data['title'] ?? ""),
                  subtitle: Text(
                    "Deadline: ${deadline.day}/${deadline.month}/${deadline.year}",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ViewSubmissionsScreen(assignmentId: doc.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UploadAssignmentFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Create New Assignment',
      ),
    );
  }
}
class UploadAssignmentFormScreen extends StatefulWidget {
  const UploadAssignmentFormScreen({super.key});

  @override
  State<UploadAssignmentFormScreen> createState() =>
      _UploadAssignmentFormScreenState();
}

class _UploadAssignmentFormScreenState
    extends State<UploadAssignmentFormScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  File? file;
  Uint8List? webFile;
  String? fileName;

  DateTime? deadline;
  bool loading = false;

  Future pickFile() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(withData: true);

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          fileName = result.files.single.name;

          if (kIsWeb) {
            webFile = result.files.single.bytes;
            file = null;
          } else {
            file = File(result.files.single.path!);
            webFile = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => deadline = picked);
    }
  }

  Future upload() async {
    if (titleController.text.isEmpty ||
        descController.text.isEmpty ||
        deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      String fileUrl = "no_file";

      if (file != null || webFile != null) {
        fileUrl = await StorageService().uploadFileFlexible(
          file: file,
          webFile: webFile,
          path: 'assignments/${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // ✅ FIXED: correct function
   await FirebaseFirestore.instance.collection('assignments').add({
  'title': titleController.text.trim(),
  'description': descController.text.trim(),
  'fileUrl': fileUrl,
  'fileName': fileName?.trim().isNotEmpty == true ? fileName : 'no_file',
  'deadline': Timestamp.fromDate(deadline!),
  'createdAt': Timestamp.now(),
});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Uploaded ✅")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Assignment")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: pickFile,
                child: const Text("Pick File"),
              ),

              if (fileName != null) Text("Selected: $fileName"),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: pickDate,
                child: const Text("Select Deadline"),
              ),

              if (deadline != null)
                Text(
                  "Deadline: ${deadline!.day}/${deadline!.month}/${deadline!.year}",
                ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: loading ? null : upload,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Upload Assignment"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}