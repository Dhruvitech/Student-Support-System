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

  // Retrieve file as bytes from Firestore document ID
  Future<Uint8List?> getFileBytes(String fileId) async {
    try {
      final doc = await _firestore.collection('files').doc(fileId).get();
      if (doc.exists && doc.data() != null) {
        final base64String = doc.data()!['data'] as String?;
        if (base64String != null) {
          return base64Decode(base64String);
        }
      }
      return null;
    } catch (e) {
      print("Error retrieving file: $e");
      return null;
    }
  }

  // Create a data URL for file viewing in browser (for web platform)
  Future<String?> getFileDataUrl(String fileId) async {
    try {
      final bytes = await getFileBytes(fileId);
      if (bytes != null) {
        final base64String = base64Encode(bytes);
        // Assume PDF or generic file
        return 'data:application/octet-stream;base64,$base64String';
      }
      return null;
    } catch (e) {
      print("Error creating data URL: $e");
      return null;
    }
  }
}