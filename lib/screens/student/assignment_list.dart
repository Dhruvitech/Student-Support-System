import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studentsupportsystem/services/firestore_service.dart';
import 'upload_assignment.dart';
import '../file_viewer_screen.dart';

class AssignmentListScreen extends StatefulWidget {
  const AssignmentListScreen({super.key});

  @override
  State<AssignmentListScreen> createState() => _AssignmentListScreenState();
}

class _AssignmentListScreenState extends State<AssignmentListScreen> {
  final FirestoreService firestoreService = FirestoreService();
  Map<String, dynamic>? studentData;
  bool loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      studentData = doc.data();
      loadingUser = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? '';

    if (loadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final branch = studentData?['branch'] ?? '';
    final semester = studentData?['semester'] ?? '';
    final division = studentData?['division'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("View Assignments")),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getStudentAssignments(
          branch: branch,
          semester: semester,
          division: division,
        ),
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

              Timestamp? deadlineStamp = data['deadline'] as Timestamp?;
              DateTime deadline = deadlineStamp != null
                  ? deadlineStamp.toDate()
                  : DateTime.now().add(const Duration(days: 1));

              bool isLate = DateTime.now().isAfter(deadline);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(data['title'] ?? ""),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['description'] ?? ""),
                      Text("Deadline: ${deadline.day}/${deadline.month}/${deadline.year}"),
                      Text(
                        isLate ? "Late ❌" : "Active ✅",
                        style: TextStyle(
                          color: isLate ? Colors.red : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (data['fileUrl'] != null && data['fileUrl'] != "no_file")
                        TextButton.icon(
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text("View Assignment File"),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FileViewerScreen(
                                  fileId: data['fileUrl'],
                                  fileName: data['title'] ?? 'Assignment',
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  trailing: StreamBuilder<QuerySnapshot>(
                    stream: firestoreService.checkSubmission(doc.id, userId),
                    builder: (context, subSnap) {
                      if (subSnap.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }

                      bool submitted = subSnap.data?.docs.isNotEmpty ?? false;

                      return ElevatedButton(
                        onPressed: submitted
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UploadAssignmentScreen(
                                      assignmentId: doc.id,
                                    ),
                                  ),
                                );
                              },
                        child: Text(submitted ? "Submitted ✅" : "Submit"),
                      );
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