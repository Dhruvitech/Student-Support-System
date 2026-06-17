import 'dart:js' as js;
import 'dart:convert';
import 'dart:typed_data';

void downloadFileWeb(Uint8List bytes, String fileName) {
  final base64Data = base64Encode(bytes);
  final safeName = fileName.replaceAll(RegExp(r'[^\w\s.-]'), '');
  String mimeType = 'application/octet-stream';
  if (safeName.toLowerCase().endsWith('.pdf')) {
    mimeType = 'application/pdf';
  } else if (safeName.toLowerCase().endsWith('.png')) {
    mimeType = 'image/png';
  } else if (safeName.toLowerCase().endsWith('.jpg') || safeName.toLowerCase().endsWith('.jpeg')) {
    mimeType = 'image/jpeg';
  } else if (safeName.toLowerCase().endsWith('.zip')) {
    mimeType = 'application/zip';
  }

  final dataUrl = 'data:$mimeType;base64,$base64Data';

  js.context.callMethod('eval', ['''
    var link = document.createElement('a');
    link.href = "$dataUrl";
    link.download = "$safeName";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  ''']);
}
