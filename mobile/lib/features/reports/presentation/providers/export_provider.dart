import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/utils/download_utils.dart';

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

class TaxExportNotifier extends Notifier<ExportState> {
  late final ApiService _api;

  @override
  ExportState build() {
    _api = ApiService();
    return ExportState();
  }

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
    await DownloadUtils.downloadFile(
      filename: fileName,
      bytes: bytes,
    );
  }
}

final taxExportProvider = NotifierProvider<TaxExportNotifier, ExportState>(TaxExportNotifier.new);
