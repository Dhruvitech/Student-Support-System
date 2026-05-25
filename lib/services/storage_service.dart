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

      // Create the file parent document
      DocumentReference fileRef = await _firestore.collection('files').add({
        'path': path,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'isChunked': true,
      });

      // Split base64File into 500,000 character chunks (approx 375KB each)
      final int chunkSize = 500000;
      int chunkIndex = 0;
      final WriteBatch batch = _firestore.batch();

      for (int i = 0; i < base64File.length; i += chunkSize) {
        final end = (i + chunkSize < base64File.length) ? i + chunkSize : base64File.length;
        final chunkData = base64File.substring(i, end);

        final chunkRef = fileRef.collection('chunks').doc(chunkIndex.toString());
        batch.set(chunkRef, {
          'data': chunkData,
          'index': chunkIndex,
        });
        chunkIndex++;
      }

      await batch.commit();
      print("File saved to Firestore with chunked ID: ${fileRef.id}");
      return fileRef.id;

    } catch (e) {
      print("Error saving file: $e");
      rethrow;
    }
  }

  // Retrieve file as bytes from Firestore document ID
  Future<Uint8List?> getFileBytes(String fileId) async {
    try {
      final doc = await _firestore.collection('files').doc(fileId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final data = doc.data()!;
      final isChunked = data['isChunked'] as bool? ?? false;

      if (isChunked) {
        final chunksSnapshot = await _firestore
            .collection('files')
            .doc(fileId)
            .collection('chunks')
            .get();

        if (chunksSnapshot.docs.isEmpty) {
          return null;
        }

        // Sort chunks by index
        final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(chunksSnapshot.docs)
          ..sort((a, b) {
            final aIndex = a.data()['index'] as int? ?? 0;
            final bIndex = b.data()['index'] as int? ?? 0;
            return aIndex.compareTo(bIndex);
          });

        final StringBuffer buffer = StringBuffer();
        for (final chunkDoc in docs) {
          final chunkData = chunkDoc.data()['data'] as String?;
          if (chunkData != null) {
            buffer.write(chunkData);
          }
        }

        return base64Decode(buffer.toString());
      } else {
        // Fallback for old non-chunked files
        final base64String = data['data'] as String?;
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