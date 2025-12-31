import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
import '../models/payroll_model.dart';
import '../utils/payroll_utils.dart';

// =============================================================================
// PROVIDER
// =============================================================================

final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  return PayrollRepository(
    dio: ref.read(apiClientProvider),
    storage: const FlutterSecureStorage(),
  );
});

// =============================================================================
// REPOSITORY
// =============================================================================

/// Repository for managing payroll calculations and records.
///
/// Handles CRUD operations for payroll drafts, calculations,
/// and payslip generation.
class PayrollRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'access_token';

  PayrollRepository({
    required Dio dio,
    required FlutterSecureStorage storage,
  })  : _dio = dio,
        _storage = storage;

  // ---------------------------------------------------------------------------
  // Public Methods: Calculations
  // ---------------------------------------------------------------------------

  /// Calculate payroll for specified workers.
  ///
  /// Optionally filter by date range. Returns calculated payroll items
  /// with tax breakdowns and net pay.
  ///
  /// Throws [PayrollRepositoryException] on failure.
  Future<List<PayrollCalculation>> calculatePayroll(
    List<String> workerIds, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _executeRequest(
      operation: 'calculate payroll',
      request: () async {
        final response = await _authenticatedPost(
          '/payroll/calculate',
          data: {
            'workerIds': workerIds,
            if (startDate != null) 'startDate': startDate.toIso8601String(),
            if (endDate != null) 'endDate': endDate.toIso8601String(),
          },
        );

        return _parsePayrollList(response.data);
      },
    );
  }

  /// Process payroll batch for payment.
  ///
  /// Marks the specified workers' payroll as processed and ready for payment.
  /// Returns processing result with success/failure details.
  /// 
  /// Note: Backend uses async queue processing. If status is 'PROCESSING',
  /// the job is queued and will complete asynchronously.
  Future<PayrollProcessingResult> processPayroll(
    List<String> workerIds,
    String payPeriodId, {
    bool skipPayout = false,
  }) async {
    return _executeRequest(
      operation: 'process payroll',
      request: () async {
        final response = await _authenticatedPost(
          '/payroll/process',
          data: {
            'workerIds': workerIds,
            'payPeriodId': payPeriodId,
            'skipPayout': skipPayout,
          },
        );

        final data = response.data as Map<String, dynamic>;
        
        // Handle async queue response: {status: 'PROCESSING', jobId: '...', ...}
        if (data['status'] == 'PROCESSING') {
          // Job is queued - return a "pending" result
          // The actual result will be available when the job completes
          return PayrollProcessingResult(
            successCount: workerIds.length, // Optimistic - assume all will succeed
            failureCount: 0,
            results: workerIds.map((id) => WorkerPaymentResult(
              workerId: id,
              workerName: 'Processing...',
              success: true,
            )).toList(),
          );
        }
        
        // Handle immediate completion response with payoutResults
        final payoutResults = data['payoutResults'] as Map<String, dynamic>? ?? {};
        return PayrollProcessingResult.fromJson(payoutResults);
      },
    );
  }

  /// Verify if user has sufficient wallet balance for payroll.
  ///
  /// Returns fund verification result with available balance, required amount,
  /// and whether payroll can proceed.
  Future<FundVerificationResult> verifyFunds(String payPeriodId) async {
    return _executeRequest(
      operation: 'verify funds',
      request: () async {
        final response = await _authenticatedGet(
          '/payroll/verify-funds/$payPeriodId',
        );
        return FundVerificationResult.fromJson(response.data);
      },
    );
  }

  /// DEV ONLY: Manually top up wallet balance for testing.
  /// Only works in development mode.
  Future<Map<String, dynamic>> devTopup(double amount) async {
    return _executeRequest(
      operation: 'dev topup',
      request: () async {
        final response = await _authenticatedPost(
          '/payments/dev/topup',
          data: {'amount': amount},
        );
        return response.data as Map<String, dynamic>;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Public Methods: Draft Management
  // ---------------------------------------------------------------------------

  /// Save payroll items as draft for a pay period.
  ///
  /// Creates or updates draft payroll records that can be edited
  /// before finalization.
  Future<List<PayrollCalculation>> saveDraftPayroll(
    String payPeriodId,
    List<Map<String, dynamic>> items,
  ) async {
    return _executeRequest(
      operation: 'save draft payroll',
      request: () async {
        final response = await _authenticatedPost(
          '/payroll/draft',
          data: {
            'payPeriodId': payPeriodId,
            'payrollItems': items,
          },
        );

        return _parsePayrollList(response.data);
      },
    );
  }

  /// Get draft payroll items for a pay period.
  ///
  /// Returns empty list if no draft exists.
  Future<List<PayrollCalculation>> getDraftPayroll(String payPeriodId) async {
    return _executeRequest(
      operation: 'get draft payroll',
      request: () async {
        final response = await _authenticatedGet('/payroll/draft/$payPeriodId');
        return _parsePayrollList(response.data);
      },
    );
  }

  /// Get payroll records for a pay period (all statuses).
  Future<List<PayrollCalculation>> getPeriodRecords(String payPeriodId) async {
    return _executeRequest(
      operation: 'get period records',
      request: () async {
        final response =
            await _authenticatedGet('/payroll/period-records/$payPeriodId');
        return _parsePayrollList(response.data);
      },
    );
  }

  /// Update a single payroll item in the draft.
  ///
  /// Allows editing bonuses, deductions, and other adjustments
  /// before finalization.
  Future<PayrollCalculation> updatePayrollItem(
    String payrollRecordId,
    Map<String, dynamic> updates,
  ) async {
    return _executeRequest(
      operation: 'update payroll item',
      request: () async {
        final response = await _authenticatedPatch(
          '/payroll/draft/$payrollRecordId',
          data: updates,
        );

        final result = _safeParsePayroll(response.data);
        if (result == null) {
          throw const PayrollRepositoryException(
            operation: 'update payroll item',
            message: 'Failed to parse updated payroll record',
          );
        }
        return result;
      },
    );
  }

  /// Delete a payroll item from the draft.
  Future<void> deletePayrollItem(String payrollRecordId) async {
    return _executeRequest(
      operation: 'delete payroll item',
      request: () => _authenticatedDelete('/payroll/draft/$payrollRecordId'),
    );
  }

  // ---------------------------------------------------------------------------
  // Public Methods: Finalization
  // ---------------------------------------------------------------------------

  /// Finalize payroll for a pay period.
  ///
  /// Locks the payroll and prepares it for payment processing.
  /// After finalization, items cannot be edited.
  Future<void> finalizePayroll(String payPeriodId) async {
    return _executeRequest(
      operation: 'finalize payroll',
      request: () => _authenticatedPost('/payroll/finalize/$payPeriodId'),
    );
  }

  // ---------------------------------------------------------------------------
  // Public Methods: Payslips
  // ---------------------------------------------------------------------------

  /// Download payslip PDF for a payroll record.
  ///
  /// Returns raw PDF bytes that can be saved or displayed.
  Future<List<int>> downloadPayslip(String payrollRecordId) async {
    return _executeRequest(
      operation: 'download payslip',
      request: () async {
        final token = await _getToken();
        final response = await _dio.get<List<int>>(
          '/payroll/payslip/$payrollRecordId',
          options: Options(
            headers: {
              ..._authHeaders(token),
              'Accept': '*/*',
            },
            responseType: ResponseType.bytes,
          ),
        );

        return response.data ?? [];
      },
    );
  }

  /// Get payslip preview data (without PDF generation).
  Future<PayslipPreview> getPayslipPreview(String payrollRecordId) async {
    return _executeRequest(
      operation: 'get payslip preview',
      request: () async {
        final response = await _authenticatedGet(
          '/payroll/payslip/$payrollRecordId/preview',
        );

        try {
          return PayslipPreview.fromJson(response.data);
        } catch (e) {
             throw const PayrollRepositoryException(
            operation: 'get payslip preview',
            message: 'Failed to parse payslip preview data',
          );
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Public Methods: Summary & Statistics
  // ---------------------------------------------------------------------------

  /// Get payroll summary for a pay period.
  Future<PayrollSummary> getPayrollSummary(String payPeriodId) async {
    return _executeRequest(
      operation: 'get payroll summary',
      request: () async {
        final response = await _authenticatedGet(
          '/payroll/summary/$payPeriodId',
        );

        return PayrollSummary.fromJson(response.data);
      },
    );
  }

  /// Get payment history for a specific worker.
  Future<List<WorkerPaymentHistoryItem>> getWorkerHistory(String workerId) async {
    return _executeRequest(
      operation: 'get worker history',
      request: () async {
        final response = await _authenticatedGet('/payroll/worker/$workerId');
        
        if (response.data is! List) return [];
        
        return (response.data as List).map((json) {
          final map = json as Map<String, dynamic>;
          final period = map['payPeriod'] as Map<String, dynamic>?;
          
          return WorkerPaymentHistoryItem(
            id: map['id'] ?? '',
            payPeriodName: period?['name'] ?? 'Unknown Period',
            periodStart: period?['startDate'] != null 
                ? DateTime.parse(period!['startDate']) 
                : DateTime.now(),
            grossSalary: PayrollUtils.parseDouble(map['grossSalary']),
            totalDeductions: PayrollUtils.parseDeductions(map),
            netPay: PayrollUtils.parseDouble(map['netSalary']),
            status: (map['status'] as String? ?? 'CLOSED').toUpperCase(),
            paidAt: map['finalizedAt'] != null 
                ? DateTime.parse(map['finalizedAt']) 
                : null,
          );
        }).toList();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Private Methods: HTTP Helpers
  // ---------------------------------------------------------------------------

  Future<String?> _getToken() => _storage.read(key: _tokenKey);

  Map<String, String> _authHeaders(String? token) => {
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Response> _authenticatedGet(String path) async {
    final token = await _getToken();
    return _dio.get(
      path,
      options: Options(headers: _authHeaders(token)),
    );
  }

  Future<Response> _authenticatedPost(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final token = await _getToken();
    return _dio.post(
      path,
      data: data,
      options: Options(headers: _authHeaders(token)),
    );
  }

  Future<Response> _authenticatedPatch(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final token = await _getToken();
    return _dio.patch(
      path,
      data: data,
      options: Options(headers: _authHeaders(token)),
    );
  }

  Future<Response> _authenticatedDelete(String path) async {
    final token = await _getToken();
    return _dio.delete(
      path,
      options: Options(headers: _authHeaders(token)),
    );
  }

  // ---------------------------------------------------------------------------
  // Private Methods: Response Parsing
  // ---------------------------------------------------------------------------

  /// Safely parse a single payroll calculation from JSON.
  PayrollCalculation? _safeParsePayroll(dynamic item) {
    if (item is! Map) return null;
    
    try {
      // Create a mutable copy to sanitize data
      final Map<String, dynamic> json = Map<String, dynamic>.from(item);

      // Helper to ensure double values
      double toDouble(dynamic val) {
        if (val == null) return 0.0;
        if (val is num) return val.toDouble();
        if (val is String) return double.tryParse(val) ?? 0.0;
        return 0.0;
      }

      // Ensure required string fields are not null
      if (json['workerId'] == null) json['workerId'] = '';
      if (json['workerName'] == null) json['workerName'] = 'Unknown Worker';
      if (json.containsKey('status') && json['status'] == null) {
        json.remove('status'); 
      }

      // Ensure numeric fields
      json['grossSalary'] = toDouble(json['grossSalary']);
      json['bonuses'] = toDouble(json['bonuses']);
      json['otherEarnings'] = toDouble(json['otherEarnings']);
      json['otherDeductions'] = toDouble(json['otherDeductions']);
      json['netPay'] = toDouble(json['netPay']);

      // Ensure tax breakdown numbers
      if (json['taxBreakdown'] != null && json['taxBreakdown'] is Map) {
        final tax = Map<String, dynamic>.from(json['taxBreakdown']);
        tax['nssf'] = toDouble(tax['nssf']);
        tax['nhif'] = toDouble(tax['nhif']);
        tax['housingLevy'] = toDouble(tax['housingLevy']);
        tax['paye'] = toDouble(tax['paye']);
        tax['totalDeductions'] = toDouble(tax['totalDeductions']);
        json['taxBreakdown'] = tax;
      }

      return PayrollCalculation.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  List<PayrollCalculation> _parsePayrollList(dynamic data) {
    List<dynamic> items;

    if (data is Map && data.containsKey('payrollItems')) {
      items = data['payrollItems'] as List;
    } else if (data is List) {
      items = data;
    } else {
      items = [];
    }

    return items
        .map((item) => _safeParsePayroll(item))
        .whereType<PayrollCalculation>()
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Private Methods: Error Handling
  // ---------------------------------------------------------------------------

  /// Execute a request with standardized error handling.
  Future<T> _executeRequest<T>({
    required String operation,
    required Future<T> Function() request,
  }) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw PayrollRepositoryException(
        operation: operation,
        message: _extractErrorMessage(e),
        originalError: e,
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is PayrollRepositoryException) rethrow;
      throw PayrollRepositoryException(
        operation: operation,
        message: e.toString(),
        originalError: e,
      );
    }
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map) {
      // Try common error message fields
      return data['message'] as String? ??
          data['error'] as String? ??
          data['detail'] as String? ??
          'An error occurred';
    }

    return error.message ?? 'Network error occurred';
  }
}

// =============================================================================
// EXCEPTIONS
// =============================================================================

/// Exception thrown by [PayrollRepository] operations.
class PayrollRepositoryException implements Exception {
  final String operation;
  final String message;
  final Object? originalError;
  final int? statusCode;

  const PayrollRepositoryException({
    required this.operation,
    required this.message,
    this.originalError,
    this.statusCode,
  });

  @override
  String toString() => 'Failed to $operation: $message';

  bool get isNetworkError => originalError is DioException;

  bool get isUnauthorized => statusCode == 401;

  bool get isForbidden => statusCode == 403;

  bool get isNotFound => statusCode == 404;

  bool get isServerError => statusCode != null && statusCode! >= 500;

  bool get isValidationError => statusCode == 400 || statusCode == 422;
}

// =============================================================================
// RESULT TYPES
// =============================================================================

/// Simple model for worker payment history list items.
class WorkerPaymentHistoryItem {
  final String id;
  final String payPeriodName;
  final DateTime periodStart;
  final double grossSalary;
  final double totalDeductions;
  final double netPay;
  final String status;
  final DateTime? paidAt;

  const WorkerPaymentHistoryItem({
    required this.id,
    required this.payPeriodName,
    required this.periodStart,
    required this.grossSalary,
    required this.totalDeductions,
    required this.netPay,
    required this.status,
    this.paidAt,
  });
}

// =============================================================================
// EXTENSIONS
// =============================================================================

/// Extension methods for [List<PayrollCalculation>].
extension PayrollCalculationListExtensions on List<PayrollCalculation> {
  /// Total gross salary across all calculations.
  double get totalGross => fold(0.0, (sum, c) => sum + c.grossSalary);

  /// Total net pay across all calculations.
  double get totalNet => fold(0.0, (sum, c) => sum + c.netPay);

  /// Total deductions across all calculations.
  double get totalDeductions =>
      fold(0.0, (sum, c) => sum + c.taxBreakdown.totalDeductions);

  /// Filter by status.
  List<PayrollCalculation> byStatus(String status) =>
      where((c) => c.status == status).toList();

  /// Get calculations that have been edited.
  List<PayrollCalculation> get edited => where((c) => c.isEdited).toList();

  /// Get calculations in draft status.
  List<PayrollCalculation> get drafts => byStatus('draft');

  /// Get calculations ready for processing.
  List<PayrollCalculation> get pending => byStatus('pending');

  /// Get processed calculations.
  List<PayrollCalculation> get processed => byStatus('processed');

  /// Sort by worker name alphabetically.
  List<PayrollCalculation> get sortedByName {
    final copy = List<PayrollCalculation>.from(this);
    copy.sort((a, b) => a.workerName.compareTo(b.workerName));
    return copy;
  }

  /// Sort by net pay descending.
  List<PayrollCalculation> get sortedByNetPayDesc {
    final copy = List<PayrollCalculation>.from(this);
    copy.sort((a, b) => b.netPay.compareTo(a.netPay));
    return copy;
  }
}
