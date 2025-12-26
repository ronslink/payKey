import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

class DownloadUtils {
  /// Download and open a file (PDF, etc.)
  /// 
  /// On Web: Triggers browser download.
  /// On Mobile: Saves to temporary directory and opens with default viewer.
  static Future<void> downloadFile({
    required String filename,
    required List<int> bytes,
    String mimeType = 'application/pdf',
  }) async {
    if (kIsWeb) {
      _downloadWeb(filename, bytes, mimeType);
    } else {
      await _downloadMobile(filename, bytes);
    }
  }

  static void _downloadWeb(String filename, List<int> bytes, String mimeType) {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> _downloadMobile(String filename, List<int> bytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = io.File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      final result = await OpenFilex.open(file.path);
      
      if (result.type != ResultType.done) {
        throw Exception('Could not open file: ${result.message}');
      }
    } catch (e) {
      throw Exception('Failed to save or open file: $e');
    }
  }
}
