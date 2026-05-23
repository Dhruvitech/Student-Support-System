import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../file_viewer_screen.dart';

class ViewSubmissionsScreen extends StatelessWidget {
  final String assignmentId;

  const ViewSubmissionsScreen({this.assignmentId = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Submissions")),
      body: StreamBuilder(
        stream: FirestoreService().getSubmissions(assignmentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No submissions yet"));
          }

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
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (enrollment.isNotEmpty) Text("Enrollment: $enrollment"),
                          const SizedBox(height: 4),
                          Text("File ID: $fileUrl", maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy),
                            tooltip: 'Copy File ID',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: fileUrl));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('File ID copied to clipboard!')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.download_rounded),
                            tooltip: 'View/Download Assignment',
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () {
                              // Navigate to file viewer
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FileViewerScreen(
                                    fileId: fileUrl,
                                    fileName: '$studentName - Submission',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
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