import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/pay_period_model.dart';

// =============================================================================
// PROVIDER
// =============================================================================

final payPeriodRepositoryProvider = Provider<PayPeriodRepository>((ref) {
  return PayPeriodRepository(ApiService());
});

// =============================================================================
// REPOSITORY
// =============================================================================

/// Repository for managing pay periods.
///
/// Handles CRUD operations, status transitions, and statistics
/// for payroll pay periods.
class PayPeriodRepository {
  final ApiService _apiService;

  PayPeriodRepository(this._apiService);

  // ---------------------------------------------------------------------------
  // Public Methods: Read Operations
  // ---------------------------------------------------------------------------

  /// Fetch all pay periods.
  ///
  /// Returns all pay periods regardless of status.
  /// Use for admin or overview screens.
  Future<List<PayPeriod>> getPayPeriods() async {
    return _executeRequest(
      operation: 'fetch pay periods',
      request: () async {
        final response = await _apiService.payPeriods.getAll();
        return _parsePayPeriodList(response.data);
      },
    );
  }

  /// Fetch pay periods filtered by status.
  ///
  /// Use for dashboards or filtered views.
  Future<List<PayPeriod>> getPayPeriodsByStatus(PayPeriodStatus status) async {
    return _executeRequest(
      operation: 'fetch pay periods by status',
      request: () async {
        final response = await _apiService.payPeriods.getByStatus(
          status.name.toUpperCase(),
        );
        return _parsePayPeriodList(response.data);
      },
    );
  }

  /// Fetch a single pay period by ID.
  Future<PayPeriod> getPayPeriod(String payPeriodId) async {
    return _executeRequest(
      operation: 'fetch pay period',
      request: () async {
        final response = await _apiService.payPeriods.getById(payPeriodId);
        final jsonMap = _normalizePayPeriodJson(response.data as Map<String, dynamic>);
        return PayPeriod.fromJson(jsonMap);
      },
    );
  }

  /// Alias for [getPayPeriod] for backward compatibility.
  Future<PayPeriod> getPayPeriodById(String payPeriodId) => getPayPeriod(payPeriodId);

  /// Fetch the current active pay period(s).
  ///
  /// Returns a list as there may be multiple active periods
  /// for different frequencies.
  Future<List<PayPeriod>> getCurrentPayPeriods() async {
    return _executeRequest(
      operation: 'fetch current pay period',
      request: () async {
        final response = await _apiService.payPeriods.getCurrent();
        return _parsePayPeriodList(response.data);
      },
    );
  }

  /// Alias for getCurrentPayPeriods for backward compatibility.
  Future<List<PayPeriod>> getCurrentPayPeriod() async {
    return getCurrentPayPeriods();
  }

  /// Fetch statistics for a pay period.
  ///
  /// Returns aggregated data including total workers, amounts, and status counts.
  Future<PayPeriodStatistics> getPayPeriodStatistics(String payPeriodId) async {
    return _executeRequest(
      operation: 'fetch pay period statistics',
      request: () async {
        final response = await _apiService.payPeriods.getStatistics(payPeriodId);
        return PayPeriodStatistics.fromJson(response.data as Map<String, dynamic>);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Public Methods: Write Operations
  // ---------------------------------------------------------------------------

  /// Create a new pay period.
  Future<PayPeriod> createPayPeriod(CreatePayPeriodRequest request) async {
    return _executeRequest(
      operation: 'create pay period',
      request: () async {
        final response = await _apiService.payPeriods.create(
          _buildCreatePayload(request),
        );
        final jsonMap = _normalizePayPeriodJson(response.data as Map<String, dynamic>);
        return PayPeriod.fromJson(jsonMap);
      },
    );
  }

  /// Update an existing pay period.
  ///
  /// Only fields present in [request] will be updated.
  Future<PayPeriod> updatePayPeriod(
    String payPeriodId,
    UpdatePayPeriodRequest request,
  ) async {
    return _executeRequest(
      operation: 'update pay period',
      request: () async {
        final response = await _apiService.payPeriods.update(
          payPeriodId,
          _buildUpdatePayload(request),
        );
        final jsonMap = _normalizePayPeriodJson(response.data as Map<String, dynamic>);
        return PayPeriod.fromJson(jsonMap);
      },
    );
  }

  /// Generate pay periods for a range.
  Future<List<PayPeriod>> generatePayPeriods({
    required String frequency,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _executeRequest(
      operation: 'generate pay periods',
      request: () async {
        final response = await _apiService.payPeriods.generate(
          frequency: frequency,
          startDate: _formatDate(startDate),
          endDate: _formatDate(endDate),
        );
        return _parsePayPeriodList(response.data);
      },
    );
  }

  /// Delete a pay period.
  ///
  /// Only draft periods can be deleted.
  Future<void> deletePayPeriod(String payPeriodId) async {
    return _executeRequest(
      operation: 'delete pay period',
      request: () => _apiService.payPeriods.delete(payPeriodId),
    );
  }

  // ---------------------------------------------------------------------------
  // Public Methods: Status Transitions
  // ---------------------------------------------------------------------------

  /// Activate a draft pay period.
  ///
  /// Transition: DRAFT -> ACTIVE
  Future<PayPeriod> activatePayPeriod(String payPeriodId) async {
    return _transitionStatus(payPeriodId, 'activate');
  }

  /// Start processing a pay period.
  ///
  /// Transition: ACTIVE -> PROCESSING
  Future<PayPeriod> processPayPeriod(String payPeriodId) async {
    return _transitionStatus(payPeriodId, 'process');
  }

  /// Complete a pay period.
  ///
  /// Transition: PROCESSING -> COMPLETED
  Future<PayPeriod> completePayPeriod(String payPeriodId) async {
    return _transitionStatus(payPeriodId, 'complete');
  }

  /// Close a completed pay period.
  ///
  /// Transition: COMPLETED -> CLOSED
  Future<PayPeriod> closePayPeriod(String payPeriodId) async {
    return _transitionStatus(payPeriodId, 'close');
  }

  /// Reopen a closed pay period.
  ///
  /// Transition: CLOSED -> COMPLETED (or ACTIVE depending on backend logic)
  Future<PayPeriod> reopenPayPeriod(String payPeriodId) async {
    return _transitionStatus(payPeriodId, 'reopen');
  }

  /// Generic status transition using action name.
  Future<void> updatePayPeriodStatus(String payPeriodId, String action) async {
    return _executeRequest(
      operation: 'update pay period status',
      request: () => _apiService.payPeriods.updateStatus(payPeriodId, action),
    );
  }

  // ---------------------------------------------------------------------------
  // Public Methods: Payslips
  // ---------------------------------------------------------------------------

  /// Generate payslips for all workers in a pay period.
  Future<void> generatePayslips(String payPeriodId) async {
    return _executeRequest(
      operation: 'generate payslips',
      request: () => _apiService.post(
        '/payroll/payslips/generate/$payPeriodId',
        data: {},
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Private Methods: Status Transition Helper
  // ---------------------------------------------------------------------------

  Future<PayPeriod> _transitionStatus(String payPeriodId, String action) async {
    return _executeRequest(
      operation: '$action pay period',
      request: () async {
        switch (action) {
          case 'activate':
            await _apiService.payPeriods.activate(payPeriodId);
            break;
          case 'process':
            await _apiService.payPeriods.process(payPeriodId);
            break;
          case 'complete':
            await _apiService.payPeriods.complete(payPeriodId);
            break;
          case 'close':
            await _apiService.payPeriods.close(payPeriodId);
            break;
          case 'reopen':
            await _apiService.payPeriods.reopen(payPeriodId);
            break;
          default:
            throw ArgumentError('Unknown action: $action');
        }
        return getPayPeriod(payPeriodId);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Private Methods: Payload Builders
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _buildCreatePayload(CreatePayPeriodRequest request) {
    return {
      'name': request.name,
      'startDate': _formatDate(request.startDate),
      'endDate': _formatDate(request.endDate),
      'frequency': request.frequency.name.toUpperCase(),
      if (request.notes != null) 'notes': request.notes,
      'isOffCycle': request.isOffCycle,
    };
  }

  Map<String, dynamic> _buildUpdatePayload(UpdatePayPeriodRequest request) {
    return {
      if (request.name != null) 'name': request.name,
      if (request.startDate != null) 'startDate': _formatDate(request.startDate!),
      if (request.endDate != null) 'endDate': _formatDate(request.endDate!),
      if (request.frequency != null) 'frequency': request.frequency!.name.toUpperCase(),
      if (request.status != null) 'status': request.status!.name.toUpperCase(),
      if (request.notes != null) 'notes': request.notes,
    };
  }

  String _formatDate(DateTime date) => date.toIso8601String().split('T')[0];

  // ---------------------------------------------------------------------------
  // Private Methods: Response Parsing
  // ---------------------------------------------------------------------------

  /// Parse pay period list from various response formats.
  ///
  /// Handles:
  /// - Direct array: `[{...}, {...}]`
  /// - Wrapped array: `{ "data": [{...}, {...}] }`
  List<PayPeriod> _parsePayPeriodList(dynamic data) {
    List<dynamic> items;

    if (data is List) {
      items = data;
    } else if (data is Map && data['data'] is List) {
      items = data['data'] as List;
    } else {
      _logDebug('Unexpected response format: ${data.runtimeType}');
      items = [];
    }

    final results = <PayPeriod>[];

    for (final json in items) {
      try {
        final jsonMap = _normalizePayPeriodJson(json);
        final payPeriod = PayPeriod.fromJson(jsonMap);
        results.add(payPeriod);
      } catch (e) {
        _logDebug('Error parsing pay period: $e\nJSON: $json');
        // Continue parsing remaining items
      }
    }

    return results;
  }

  /// Normalize pay period JSON data before parsing
  ///
  /// Handles frequency case normalization and other data cleanup
  Map<String, dynamic> _normalizePayPeriodJson(dynamic json) {
    final jsonMap = Map<String, dynamic>.from(json as Map);
    
    // Fix frequency case issue - convert to uppercase
    if (jsonMap['frequency'] is String) {
      jsonMap['frequency'] = jsonMap['frequency'].toString().toUpperCase();
    }
    
    // Handle other potential data normalization here if needed
    return jsonMap;
  }

  // ---------------------------------------------------------------------------
  // Private Methods: Error Handling
  // ---------------------------------------------------------------------------

  Future<T> _executeRequest<T>({
    required String operation,
    required Future<T> Function() request,
  }) async {
    try {
      return await request();
    } catch (e, stack) {
      _logDebug('Error in $operation: $e\n$stack');

      if (e is PayPeriodRepositoryException) rethrow;

      throw PayPeriodRepositoryException(
        operation: operation,
        message: _apiService.getErrorMessage(e),
        originalError: e,
      );
    }
  }

  void _logDebug(String message) {
    if (kDebugMode) {
      print('[PayPeriodRepository] $message');
    }
  }
}

// =============================================================================
// EXCEPTIONS
// =============================================================================

/// Exception thrown by [PayPeriodRepository] operations.
class PayPeriodRepositoryException implements Exception {
  final String operation;
  final String message;
  final Object? originalError;

  const PayPeriodRepositoryException({
    required this.operation,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'Failed to $operation: $message';
}

// =============================================================================
// STATISTICS MODEL
// =============================================================================

/// Statistics for a pay period.
class PayPeriodStatistics {
  final int totalWorkers;
  final int processedPayments;
  final int pendingPayments;
  final double totalGrossAmount;
  final double totalNetAmount;
  final double totalTaxAmount;
  final TaxSummary? taxSummary;

  const PayPeriodStatistics({
    required this.totalWorkers,
    required this.processedPayments,
    required this.pendingPayments,
    required this.totalGrossAmount,
    required this.totalNetAmount,
    required this.totalTaxAmount,
    this.taxSummary,
  });

  factory PayPeriodStatistics.fromJson(Map<String, dynamic> json) {
    // Handle nested 'statistics' object if present
    final stats = json['statistics'] as Map<String, dynamic>? ?? json;

    return PayPeriodStatistics(
      totalWorkers: _toInt(stats['totalWorkers']),
      processedPayments: _toInt(stats['processedPayments']),
      pendingPayments: _toInt(stats['pendingPayments']),
      totalGrossAmount: _toDouble(stats['totalGrossAmount']),
      totalNetAmount: _toDouble(stats['totalNetAmount']),
      totalTaxAmount: _toDouble(stats['totalTaxAmount']),
      taxSummary: json['taxSummary'] != null
          ? TaxSummary.fromJson(json['taxSummary'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Completion percentage (0-100).
  double get completionPercentage {
    if (totalWorkers == 0) return 0;
    return (processedPayments / totalWorkers) * 100;
  }

  /// Whether all workers have been processed.
  bool get isComplete => totalWorkers > 0 && processedPayments >= totalWorkers;

  /// Convert to map for display.
  Map<String, dynamic> toDisplayMap() => {
        'totalWorkers': totalWorkers,
        'processedPayments': processedPayments,
        'pendingPayments': pendingPayments,
        'totalGrossAmount': totalGrossAmount,
        'totalNetAmount': totalNetAmount,
        'totalTaxAmount': totalTaxAmount,
        if (taxSummary != null)
          'taxSummary': {
            'paye': taxSummary!.paye,
            'nhif': taxSummary!.nhif,
            'nssf': taxSummary!.nssf,
            'housingLevy': taxSummary!.housingLevy,
            'total': taxSummary!.total,
          },
      };

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Tax summary breakdown.
class TaxSummary {
  final double paye;
  final double nhif;
  final double nssf;
  final double housingLevy;
  final double total;

  const TaxSummary({
    required this.paye,
    required this.nhif,
    required this.nssf,
    required this.housingLevy,
    required this.total,
  });

  factory TaxSummary.fromJson(Map<String, dynamic> json) {
    final paye = _toDouble(json['paye']);
    final nhif = _toDouble(json['nhif']);
    final nssf = _toDouble(json['nssf']);
    final housingLevy = _toDouble(json['housingLevy']);

    return TaxSummary(
      paye: paye,
      nhif: nhif,
      nssf: nssf,
      housingLevy: housingLevy,
      total: json['total'] != null
          ? _toDouble(json['total'])
          : paye + nhif + nssf + housingLevy,
    );
  }

  /// Convert to map for display.
  Map<String, double> toDisplayMap() => {
        'PAYE': paye,
        'NHIF': nhif,
        'NSSF': nssf,
        'Housing Levy': housingLevy,
      };

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

// =============================================================================
// EXTENSIONS
// =============================================================================

/// Extension methods for [List<PayPeriod>].
extension PayPeriodListExtensions on List<PayPeriod> {
  /// Filter by status.
  List<PayPeriod> byStatus(PayPeriodStatus status) =>
      where((p) => p.status == status).toList();

  /// Get draft periods.
  List<PayPeriod> get drafts => byStatus(PayPeriodStatus.draft);

  /// Get active periods.
  List<PayPeriod> get active => byStatus(PayPeriodStatus.active);

  /// Get processing periods.
  List<PayPeriod> get processing => byStatus(PayPeriodStatus.processing);

  /// Get completed periods.
  List<PayPeriod> get completed => byStatus(PayPeriodStatus.completed);

  /// Get closed periods.
  List<PayPeriod> get closed => byStatus(PayPeriodStatus.closed);

  /// Sort by start date descending (newest first).
  List<PayPeriod> get sortedByDateDesc {
    final copy = List<PayPeriod>.from(this);
    copy.sort((a, b) => b.startDate.compareTo(a.startDate));
    return copy;
  }

  /// Sort by start date ascending (oldest first).
  List<PayPeriod> get sortedByDateAsc {
    final copy = List<PayPeriod>.from(this);
    copy.sort((a, b) => a.startDate.compareTo(b.startDate));
    return copy;
  }

  /// Find period containing a specific date.
  PayPeriod? findByDate(DateTime date) {
    try {
      return firstWhere(
        (p) => date.isAfter(p.startDate.subtract(const Duration(days: 1))) &&
            date.isBefore(p.endDate.add(const Duration(days: 1))),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get the most recent period.
  PayPeriod? get mostRecent {
    if (isEmpty) return null;
    return sortedByDateDesc.first;
  }

  /// Get periods for a specific year.
  List<PayPeriod> forYear(int year) {
    return where((p) => p.startDate.year == year).toList();
  }

  /// Get periods for a specific month.
  List<PayPeriod> forMonth(int year, int month) {
    return where(
      (p) => p.startDate.year == year && p.startDate.month == month,
    ).toList();
  }
}