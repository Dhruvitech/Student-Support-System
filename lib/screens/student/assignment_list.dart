import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:studentsupportsystem/providers/auth_provider.dart';
import 'package:studentsupportsystem/services/firestore_service.dart';
import 'upload_assignment.dart';
import '../file_viewer_screen.dart';

class AssignmentListScreen extends StatelessWidget {
  const AssignmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final authProvider = context.watch<AuthProvider>();
    final studentData = authProvider.currentUser;
    final userId = studentData?.uid ?? '';

    final classGroup = studentData?.classGroup ?? '';
    String branch = '';
    String semester = '';
    String division = '';

    if (classGroup.isNotEmpty) {
      final parts = classGroup.trim().split(RegExp(r'\s+'));
      if (parts.length >= 4) {
        branch = parts[0].trim().toUpperCase();
        semester = parts[1].replaceAll(RegExp(r'sem-', caseSensitive: false), '').trim();
        division = parts[3].trim().toUpperCase();
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("View Assignments")),
      body: (branch.isEmpty || semester.isEmpty || division.isEmpty)
          ? const Center(child: Text("No assignments found for your class"))
          : StreamBuilder<QuerySnapshot>(
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
                            Text("Faculty: ${data['facultyName'] ?? 'Admin'}"),
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