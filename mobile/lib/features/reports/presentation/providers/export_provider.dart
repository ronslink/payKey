import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/utils/download_helper.dart';

class ExportState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  ExportState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ExportState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return ExportState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class TaxExportNotifier extends StateNotifier<ExportState> {
  final ApiService _api;

  TaxExportNotifier(this._api) : super(ExportState());

  Future<void> downloadStatutoryReport({
    required String exportType,
    required DateTime startDate,
    required DateTime endDate,
    required String title,
  }) async {
    state = ExportState(isLoading: true);
    try {
      // 1. Trigger Export Generation
      final createRes = await _api.taxes.exportStatutoryReturn(
        exportType: exportType,
        startDate: startDate,
        endDate: endDate,
      );
      
      final data = createRes.data;
      final String exportId = data['id'];
      final String fileName = data['fileName'] ?? 'report_$exportType.csv';

      // 2. Download File Content
      final downloadRes = await _api.taxes.downloadExport(exportId);
      final List<int> bytes = downloadRes.data;

      // 3. Save/Download based on platform
      await _saveFile(bytes, fileName);

      state = ExportState(
        isLoading: false,
        successMessage: 'Report downloaded successfully',
      );

    } catch (e) {
      state = ExportState(
        isLoading: false,
        error: _api.getErrorMessage(e),
      );
    }
  }

  Future<void> downloadP9Zip({required int year}) async {
    state = ExportState(isLoading: true);
    try {
      final List<int> bytes = await _api.reports.downloadP9Zip(year);
      final fileName = 'P9_Returns_$year.zip';

      await _saveFile(bytes, fileName);

      state = ExportState(
        isLoading: false,
        successMessage: 'P9 Reports downloaded successfully',
      );
    } catch (e) {
      state = ExportState(
        isLoading: false,
        error: _api.getErrorMessage(e),
      );
    }
  }

  /// Cross-platform file save/download
  Future<void> _saveFile(List<int> bytes, String fileName) async {
    if (kIsWeb) {
      // Use web download helper
      downloadFileInBrowser(bytes, fileName);
    } else {
      // Use native file save
      await _saveFileNative(bytes, fileName);
    }
  }

  /// Native (mobile/desktop) file save
  Future<void> _saveFileNative(List<int> bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    // Try to open the file
    await OpenFilex.open(filePath);
  }
}

final taxExportProvider = StateNotifierProvider<TaxExportNotifier, ExportState>((ref) {
  return TaxExportNotifier(ApiService());
});
