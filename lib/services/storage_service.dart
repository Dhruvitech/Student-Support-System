import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadFileFlexible({
    File? file,
    Uint8List? webFile,
    required String path,
  }) async {
    try {
      Uint8List bytes;

      if (webFile != null) {
        bytes = webFile;
      } else if (file != null) {
        bytes = await file.readAsBytes();
      } else {
        throw Exception("No file selected");
      }

      // Convert to base64 string
      String base64File = base64Encode(bytes);

      // Save to Firestore instead of Storage
      DocumentReference ref = await _firestore.collection('files').add({
        'path': path,
        'data': base64File,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      print("File saved to Firestore with ID: ${ref.id}");

      // Return the Firestore document ID as the "URL"
      return ref.id;

    } catch (e) {
      print("Error saving file: $e");
      rethrow;
    }
  }
}