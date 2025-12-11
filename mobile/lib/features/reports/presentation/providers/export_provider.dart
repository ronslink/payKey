import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart'; // Make sure this matches pubspec

import '../../../../core/network/api_service.dart';

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
      error: error, // Nullable update logic requires care, but usually we define explicit behavior
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
      final List<int> bytes = downloadRes.data; // Assuming ResponseType.bytes

      // 3. Save to File
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // 4. Open File
      final result = await OpenFilex.open(filePath);
      
      if (result.type != ResultType.done) {
         state = ExportState(
          isLoading: false,
          error: 'File saved to $filePath, but could not be opened: ${result.message}',
        );
      } else {
        state = ExportState(
          isLoading: false,
          successMessage: 'Report downloaded successfully',
        );
      }

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
      
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/P9_Returns_$year.zip';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Open the file
      final result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
         state = ExportState(
          isLoading: false,
          error: 'File saved to $filePath, but could not be opened: ${result.message}',
        );
      } else {
        state = ExportState(
          isLoading: false,
          successMessage: 'P9 Reports downloaded successfully',
        );
      }
    } catch (e) {
      state = ExportState(
        isLoading: false,
        error: _api.getErrorMessage(e),
      );
    }
  }
}

final taxExportProvider = StateNotifierProvider<TaxExportNotifier, ExportState>((ref) {
  return TaxExportNotifier(ApiService());
});
