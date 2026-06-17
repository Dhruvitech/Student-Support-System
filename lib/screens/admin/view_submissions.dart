import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../services/storage_service.dart';
import '../file_viewer_screen.dart';

class ViewSubmissionsScreen extends StatelessWidget {
  final String assignmentId;

  const ViewSubmissionsScreen({super.key, this.assignmentId = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Submissions")),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService().getSubmissions(assignmentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No submissions yet"));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index];

              String studentId = data['studentId'];
              String fileUrl = data['fileUrl'];

              return FutureBuilder<UserModel?>(
                future: FirestoreService().getUser(studentId),
                builder: (context, userSnapshot) {

                  String studentName = "Loading...";
                  String enrollment = "";

                  if (userSnapshot.connectionState == ConnectionState.done) {
                    if (userSnapshot.hasData && userSnapshot.data != null) {
                      studentName = userSnapshot.data!.name;
                      enrollment = userSnapshot.data!.enrollmentNumber;
                    } else {
                      studentName = "Unknown Student";
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),

                    child: ListTile(
                      title: Text(
                        studentName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (enrollment.isNotEmpty)
                            Text("Enrollment: $enrollment"),

                          const SizedBox(height: 4),

                          
                        ],
                      ),

                      trailing: IconButton(
                        icon: Icon(
                          Icons.download_rounded,
                          color: Colors.blue.shade900,
                        ),
                        tooltip: 'View/Download Assignment',
                        onPressed: () async {
  final bytes = await StorageService().getFileBytes(fileUrl);

  if (bytes == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("File not found")),
    );
    return;
  }

  // Open file viewer screen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => FileViewerScreen(fileId: fileUrl,fileName: "Submission",)
    ),
  );
},
                      ),
                    ),
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