// Web-specific download implementation
// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:typed_data';

void downloadFileInBrowser(List<int> bytes, String fileName) {
  // Convert List<int> to JS Int8Array/Uint8Array for Blob
  final array = Uint8List.fromList(bytes).toJS;
  final blob = web.Blob([array].toJS);
  final url = web.URL.createObjectURL(blob);
  
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.style.display = 'none';
  
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  
  web.URL.revokeObjectURL(url);
}
