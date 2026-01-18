import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:share_plus/share_plus.dart';

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
        // Fallback: If no app can open the file, try sharing it so user can save it
        if (result.type == ResultType.noAppToOpen) {
          debugPrint('No app found to open file, attempting simple share...');
          // Using Share.shareXFiles
          await Share.shareXFiles(
            [XFile(file.path)], 
            subject: filename, // subject usually used in emails
            text: 'Here is your file: $filename'
          );
          return;
        }

        throw Exception('Could not open file: ${result.message}');
      }
    } catch (e) {
      // Re-throw if it wasn't validly handled
      throw Exception('Failed to save or open file: $e');
    }
  }
}
