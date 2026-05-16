import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studentsupportsystem/services/firestore_service.dart';
import 'package:studentsupportsystem/services/storage_service.dart';

class UploadAssignmentScreen extends StatefulWidget {
  final String assignmentId;
  const UploadAssignmentScreen({super.key, this.assignmentId = ''});

  @override
  State<UploadAssignmentScreen> createState() =>
      _UploadAssignmentScreenState();
}

class _UploadAssignmentScreenState extends State<UploadAssignmentScreen> {
  File? file;
  Uint8List? webFile;
  bool loading = false;
  String? fileName;

  // ================= PICK FILE =================
  Future pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        withData: true,
        allowMultiple: false,
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
      print('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File pick error: $e")),
        );
      }
    }
  }

  // ================= UPLOAD =================
  Future upload() async {
    if (file == null && webFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick a file first")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      String url = await StorageService().uploadFileFlexible(
        file: file,
        webFile: webFile,
        path: 'submissions/${DateTime.now().millisecondsSinceEpoch}',
      );

      await FirestoreService().submitAssignment(
        assignmentId: widget.assignmentId,
        studentId: FirebaseAuth.instance.currentUser?.uid ?? '',
        fileUrl: url,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Submitted successfully ✅")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Upload error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Assignment")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: const Text("Pick File"),
            ),
            if (fileName != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Selected: $fileName ✅"),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : upload,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}