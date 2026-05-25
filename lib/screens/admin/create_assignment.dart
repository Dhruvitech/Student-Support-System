import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studentsupportsystem/screens/admin/view_submissions.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:studentsupportsystem/providers/auth_provider.dart';

class CreateAssignmentScreen extends StatelessWidget {
  CreateAssignmentScreen({super.key});

  final FirestoreService firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assignments")),

      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getTeacherAssignments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No assignments found"),
            );
          }

          final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs)
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>?;
              final bData = b.data() as Map<String, dynamic>?;
              final aTime = (aData?['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              final bTime = (bData?['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              return bTime.compareTo(aTime);
            });

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];

              var data = doc.data() as Map<String, dynamic>;

              DateTime deadline =
                  (data['deadline'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.all(10),

                child: ListTile(
                  title: Text(data['title'] ?? ""),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Deadline: ${deadline.day}/${deadline.month}/${deadline.year}",
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "Faculty: ${data['facultyName'] ?? ''}",
                      ),

                      Text(
                        "Subject: ${data['subject'] ?? ''}",
                      ),

                      Text(
                        "Branch: ${data['branch'] ?? ''}",
                      ),

                      Text(
                        "Semester: ${data['semester'] ?? ''}",
                      ),

                      Text(
                        "Division: ${data['division'] ?? ''}",
                      ),
                    ],
                  ),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewSubmissionsScreen(
                          assignmentId: doc.id,
                        ),
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
        tooltip: 'Create New Assignment',

        child: const Icon(Icons.add),

        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const UploadAssignmentFormScreen(),
            ),
          );
        },
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
  final subjectController = TextEditingController();

  File? file;
  Uint8List? webFile;
  String? fileName;
  DateTime? deadline;
  bool loading = false;

  // ================= FILTER VARIABLES =================
  String? selectedBranch;
  String? selectedSemester;
  String? selectedDivision;

  // ================= DROPDOWN LISTS =================

  final Map<String, Map<String, String>> branchesMap = {
    '02': {'name': 'Automobile Engineering', 'abbreviation': 'AUTO'},
    '03': {'name': 'Biomedical Engineering', 'abbreviation': 'BIOMED'},
    '05': {'name': 'Chemical Engineering', 'abbreviation': 'CHEM'},
    '06': {'name': 'Civil Engineering', 'abbreviation': 'CIVIL'},
    '07': {'name': 'Computer Engineering', 'abbreviation': 'CSE'},
    '09': {'name': 'Electrical Engineering', 'abbreviation': 'ELEC'},
    '11': {'name': 'Electronics and Communication Engineering', 'abbreviation': 'EC'},
    '13': {'name': 'Environmental Engineering', 'abbreviation': 'ENV'},
    '16': {'name': 'Information Technology', 'abbreviation': 'IT'},
    '17': {'name': 'Instrumentation & Control Engineering', 'abbreviation': 'IC'},
    '19': {'name': 'Mechanical Engineering', 'abbreviation': 'MECH'},
    '23': {'name': 'Plastic Technology', 'abbreviation': 'PLASTIC'},
    '29': {'name': 'Textile Technology', 'abbreviation': 'TEXTILE'},
    '40': {'name': 'Rubber Technology', 'abbreviation': 'RUBBER'},
    '48': {'name': 'Robotics and Automation', 'abbreviation': 'ROBOTICS'},
    '52': {'name': 'Artificial Intelligence and Machine Learning', 'abbreviation': 'AIML'},
  };

  final List<String> semesters = [
    '1', '2', '3', '4', '5', '6', '7', '8'
  ];

  final List<String> divisions = [
    'A', 'B', 'C', 'D'
  ];

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    subjectController.dispose();
    super.dispose();
  }

  // ================= PICK FILE =================
  Future pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        withData: true,
      );

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
          SnackBar(
            content: Text("Error: $e"),
          ),
        );
      }
    }
  }

  // ================= PICK DATE =================
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

  // ================= UPLOAD =================
  Future upload() async {
    if (titleController.text.trim().isEmpty ||
        descController.text.trim().isEmpty ||
        subjectController.text.trim().isEmpty ||
        deadline == null ||
        selectedBranch == null ||
        selectedSemester == null ||
        selectedDivision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Fill all fields"),
        ),
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

      final authProvider = context.read<AuthProvider>();
      final facultyName = authProvider.currentUser?.name ?? 'Admin';

      await FirebaseFirestore.instance
          .collection('assignments')
          .add({
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'facultyName': facultyName,
        'subject': subjectController.text.trim(),
        'branch': selectedBranch,
        'semester': selectedSemester,
        'division': selectedDivision,
        'fileUrl': fileUrl,
        'fileName': fileName?.trim().isNotEmpty == true ? fileName : 'no_file',
        'deadline': Timestamp.fromDate(deadline!),
        'createdAt': Timestamp.now(),
        'uploadedBy': FirebaseAuth.instance.currentUser!.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Uploaded ✅"),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Assignment"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: "Subject",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedBranch,
                decoration: const InputDecoration(
                  labelText: "Branch",
                  border: OutlineInputBorder(),
                ),
                items: branchesMap.entries.map((entry) {
                  final code = entry.key;
                  final branch = entry.value;
                  return DropdownMenuItem<String>(
                    value: branch['abbreviation'],
                    child: Text(
                      "${branch['name']} ($code)",
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBranch = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedSemester,
                decoration: const InputDecoration(
                  labelText: "Semester",
                  border: OutlineInputBorder(),
                ),
                items: semesters.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text("Semester $e"),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSemester = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedDivision,
                decoration: const InputDecoration(
                  labelText: "Division",
                  border: OutlineInputBorder(),
                ),
                items: divisions.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDivision = value;
                  });
                },
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: pickFile,
                child: const Text("Pick File"),
              ),
              if (fileName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "Selected: $fileName",
                  ),
                ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: pickDate,
                child: const Text("Select Deadline"),
              ),
              if (deadline != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "Deadline: ${deadline!.day}/${deadline!.month}/${deadline!.year}",
                  ),
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