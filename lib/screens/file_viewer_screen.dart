import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';

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
      // Get temporary directory
      final tempDir = Directory.systemTemp;
      final fileName = '${widget.fileName.replaceAll(RegExp(r'[^\w\s-]'), '')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${tempDir.path}/$fileName';
      
      print('Saving file to: $filePath');
      
      // Save file to temporary location
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      
      print('File saved successfully: $filePath');

      if (!mounted) return;

      // Try to open the file
      final Uri fileUri = Uri.file(filePath);
      
      print('Attempting to open file: $fileUri');
      
      final canLaunch = await canLaunchUrl(fileUri);
      print('Can launch file: $canLaunch');
      
      if (canLaunch) {
        final launchSuccess = await launchUrl(
          fileUri,
          mode: LaunchMode.platformDefault,
        );
        
        if (!launchSuccess) {
          print('Failed to launch file');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File saved to: $filePath\n\nTap below to open with file manager'),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Open',
                  onPressed: () => _openFileManager(filePath),
                ),
              ),
            );
          }
        } else {
          print('File opened successfully');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening file...')),
            );
          }
        }
      } else {
        print('Cannot launch file, showing file manager option');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File saved to: $filePath'),
              action: SnackBarAction(
                label: 'Folder',
                onPressed: () => _openFileManager(filePath),
              ),
              duration: const Duration(seconds: 10),
            ),
          );
        }
      }
    } catch (e) {
      print('Error downloading/opening file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _openFileManager(String filePath) async {
    try {
      final directory = File(filePath).parent;
      final dirUri = Uri.directory(directory.path);
      
      if (await canLaunchUrl(dirUri)) {
        await launchUrl(dirUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening file manager: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening folder: $e')),
        );
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading file...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('File not found'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final fileBytes = snapshot.data!;

          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.insert_drive_file,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.fileName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(fileBytes.length / 1024).toStringAsFixed(2)} KB',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                    const SizedBox(height: 32),
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
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download),
                        label: Text(
                          _isDownloading ? 'Opening File...' : 'Download & Open File',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap the button above to download and open the file with your default application',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

