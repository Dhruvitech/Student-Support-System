import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:studentsupportsystem/providers/auth_provider.dart';
import 'package:studentsupportsystem/services/storage_service.dart';

class UploadAssignmentScreen extends StatefulWidget {
  final String assignmentId;

  const UploadAssignmentScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  State<UploadAssignmentScreen> createState() =>
      _UploadAssignmentScreenState();
}

class _UploadAssignmentScreenState extends State<UploadAssignmentScreen> {
  File? file;
  Uint8List? webFile;
  bool loading = false;

  String fileName = '';

  // ================= PICK FILE =================
  Future pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
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
      debugPrint('Error picking file: $e');
    }
  }

  // ================= UPLOAD =================
  Future<void> upload() async {
    final user = context.read<AuthProvider>().currentUser;

    // ❌ no file selected
    if (file == null && webFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick a file first")),
      );
      return;
    }

    // ❌ user not logged in
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    // ❌ invalid assignment id
    if (widget.assignmentId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid assignment ID")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // upload file to storage
      String url = await StorageService().uploadFileFlexible(
        file: file,
        webFile: webFile,
        path: 'submissions/${DateTime.now().millisecondsSinceEpoch}',
      );

      // save submission in firestore
      await FirebaseFirestore.instance.collection('submissions').add({
        'assignmentId': widget.assignmentId,
        'studentId': user.uid,
        'fileUrl': url,
        'fileName': fileName.isNotEmpty ? fileName : 'no_file',
        'submittedAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Submitted successfully ✅")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Upload error: $e");

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

            if (fileName.isNotEmpty)
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