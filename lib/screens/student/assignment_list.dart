import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:studentsupportsystem/services/firestore_service.dart';
import 'upload_assignment.dart';

class AssignmentListScreen extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("View Assignments")), // FIXED TITLE
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

              Timestamp? deadlineStamp = data['deadline'] as Timestamp?;
              DateTime deadline = deadlineStamp != null 
                  ? deadlineStamp.toDate() 
                  : DateTime.now().add(const Duration(days: 1)); // Default to future if null

              bool isLate = DateTime.now().isAfter(deadline);

              return Card(
                margin: const EdgeInsets.all(10),
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
                          onPressed: () async {
                            final url = Uri.parse(data['fileUrl']);
                            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not open the file')),
                                );
                              }
                            }
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