import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';
import '../utils/web_downloader.dart';

class FileViewerScreen extends StatefulWidget {
  final String fileId;
  final String fileName;

  const FileViewerScreen({
    required this.fileId,
    required this.fileName,
    super.key,
  });

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  late Future<Uint8List?> _fileBytesFuture;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _fileBytesFuture = StorageService().getFileBytes(widget.fileId);
  }

  Future<void> _downloadAndOpenFile(Uint8List fileBytes) async {
    if (!mounted) return;

    setState(() => _isDownloading = true);

    try {
      if (kIsWeb) {
        downloadFileWeb(fileBytes, widget.fileName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Downloading file...'),
            ),
          );
        }
        return;
      }

      final tempDir = Directory.systemTemp;

      final safeName =
          widget.fileName.replaceAll(RegExp(r'[^\w\s-]'), '');

      final filePath = '${tempDir.path}/$safeName.pdf';

      final file = File(filePath);

      await file.writeAsBytes(fileBytes);

      // Open PDF using url_launcher
      final fileUri = Uri.file(filePath);
      if (await canLaunchUrl(fileUri)) {
        await launchUrl(fileUri, mode: LaunchMode.platformDefault);
      } else {
        throw Exception("Could not open file at $filePath");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening file...'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: FutureBuilder<Uint8List?>(
        future: _fileBytesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.data == null) {
            return const Center(
              child: Text('File not found'),
            );
          }

          final fileBytes = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.picture_as_pdf,
                  size: 100,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),

                Text(
                  widget.fileName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  '${(fileBytes.length / 1024).toStringAsFixed(2)} KB',
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading
                        ? null
                        : () => _downloadAndOpenFile(fileBytes),
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(
                      _isDownloading
                          ? 'Opening File...'
                          : 'Download & Open File',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}