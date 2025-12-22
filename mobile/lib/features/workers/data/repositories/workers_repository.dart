import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/worker_model.dart';

// =============================================================================
// PROVIDER
// =============================================================================

final workersRepositoryProvider = Provider<WorkersRepository>((ref) {
  return WorkersRepository(ApiService());
});

// =============================================================================
// REPOSITORY
// =============================================================================

/// Repository for managing worker data.
///
/// Handles CRUD operations for workers, including mapping between
/// API responses and domain models.
class WorkersRepository {
  final ApiService _apiService;

  WorkersRepository(this._apiService);

  // ---------------------------------------------------------------------------
  // Public Methods: Read Operations
  // ---------------------------------------------------------------------------

  /// Fetches all workers for the current user.
  ///
  /// Returns a list of [WorkerModel] sorted by creation date (newest first).
  /// Throws [WorkerRepositoryException] on failure.
  Future<List<WorkerModel>> getWorkers() async {
    return _executeRequest(
      operation: 'fetch workers',
      request: () async {
        final response = await _apiService.workers.getAll();
        final data = response.data as List;
        return data.map((item) => _mapJsonToWorker(item as Map<String, dynamic>)).toList();
      },
    );
  }

  /// Fetches a single worker by ID.
  ///
  /// Throws [WorkerRepositoryException] if not found or on failure.
  Future<WorkerModel> getWorkerById(String workerId) async {
    return _executeRequest(
      operation: 'fetch worker',
      request: () async {
        final response = await _apiService.workers.getById(workerId);
        return _mapJsonToWorker(response.data);
      },
    );
  }

  /// Returns the total count of workers.
  Future<int> getWorkerCount() async {
    final workers = await getWorkers();
    return workers.length;
  }

  /// Returns only active workers.
  Future<List<WorkerModel>> getActiveWorkers() async {
    final workers = await getWorkers();
    return workers.where((w) => w.isActive).toList();
  }

  // ---------------------------------------------------------------------------
  // Public Methods: Write Operations
  // ---------------------------------------------------------------------------

  /// Creates a new worker.
  ///
  /// Returns the created [WorkerModel] with server-generated fields (id, timestamps).
  /// Throws [WorkerRepositoryException] on failure.
  Future<WorkerModel> createWorker(CreateWorkerRequest request) async {
    return _executeRequest(
      operation: 'create worker',
      request: () async {
        final response = await _apiService.workers.create(
          _mapCreateRequestToJson(request),
        );
        return _mapJsonToWorker(response.data);
      },
    );
  }

  /// Updates an existing worker.
  ///
  /// Only fields present in [request] will be updated.
  /// Returns the updated [WorkerModel].
  /// Throws [WorkerRepositoryException] on failure.
  Future<WorkerModel> updateWorker(
    String workerId,
    UpdateWorkerRequest request,
  ) async {
    return _executeRequest(
      operation: 'update worker',
      request: () async {
        final response = await _apiService.workers.update(
          workerId,
          _mapUpdateRequestToJson(request),
        );
        return _mapJsonToWorker(response.data);
      },
    );
  }

  /// Deletes a worker by ID.
  ///
  /// Throws [WorkerRepositoryException] on failure.
  Future<void> deleteWorker(String workerId) async {
    return _executeRequest(
      operation: 'delete worker',
      request: () => _apiService.workers.delete(workerId),
    );
  }

  /// Terminates a worker (soft delete).
  ///
  /// Sets the worker's [isActive] to false and records termination date.
  Future<WorkerModel> terminateWorker(String workerId) async {
    return updateWorker(
      workerId,
      UpdateWorkerRequest(isActive: false),
    );
  }

  /// Reactivates a previously terminated worker.
  Future<WorkerModel> reactivateWorker(String workerId) async {
    return updateWorker(
      workerId,
      UpdateWorkerRequest(isActive: true),
    );
  }

  // ---------------------------------------------------------------------------
  // Private Methods: Request Execution
  // ---------------------------------------------------------------------------

  /// Executes an API request with standardized error handling.
  Future<T> _executeRequest<T>({
    required String operation,
    required Future<T> Function() request,
  }) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw WorkerRepositoryException(
        operation: operation,
        message: _apiService.getErrorMessage(e),
        originalError: e,
      );
    } catch (e) {
      if (e is WorkerRepositoryException) rethrow;
      throw WorkerRepositoryException(
        operation: operation,
        message: e.toString(),
        originalError: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private Methods: JSON Mapping
  // ---------------------------------------------------------------------------

  /// Maps API JSON response to [WorkerModel].
  WorkerModel _mapJsonToWorker(Map<String, dynamic> json) {
    return WorkerModel.fromJson({
      'id': json['id'],
      'name': json['name'],
      'phoneNumber': json['phoneNumber'],
      'salaryGross': _toDouble(json['salaryGross']),
      'startDate': json['startDate']?.toString(),
      'dateOfBirth': json['dateOfBirth']?.toString(),
      'employmentType': json['employmentType'] ?? _Defaults.employmentType,
      'hourlyRate': _toNullableDouble(json['hourlyRate']),
      'propertyId': json['propertyId'],
      'email': json['email'],
      'idNumber': json['idNumber'],
      'kraPin': json['kraPin'],
      'nssfNumber': json['nssfNumber'],
      'nhifNumber': json['nhifNumber'],
      'jobTitle': json['jobTitle'],
      'housingAllowance': _toDouble(json['housingAllowance']),
      'transportAllowance': _toDouble(json['transportAllowance']),
      'paymentFrequency': json['paymentFrequency'] ?? _Defaults.paymentFrequency,
      'paymentMethod': json['paymentMethod'] ?? _Defaults.paymentMethod,
      'mpesaNumber': json['mpesaNumber'],
      'bankName': json['bankName'],
      'bankAccount': json['bankAccount'],
      'notes': json['notes'],
      'terminatedAt': json['terminatedAt']?.toString(),
      'createdAt': json['createdAt']?.toString(),
      'updatedAt': json['updatedAt']?.toString(),
      'isActive': json['isActive'] ?? _Defaults.isActive,
    });
  }

  /// Maps [CreateWorkerRequest] to API JSON payload.
  Map<String, dynamic> _mapCreateRequestToJson(CreateWorkerRequest request) {
    return {
      'name': request.name,
      'phoneNumber': request.phoneNumber,
      'salaryGross': request.salaryGross,
      if (request.startDate != null) 'startDate': request.startDate!.toIso8601String(),
      if (request.dateOfBirth != null) 'dateOfBirth': request.dateOfBirth!.toIso8601String(),
      'employmentType': request.employmentType,
      'hourlyRate': request.hourlyRate,
      'propertyId': request.propertyId,
      'email': request.email,
      'idNumber': request.idNumber,
      'kraPin': request.kraPin,
      'nssfNumber': request.nssfNumber,
      'nhifNumber': request.nhifNumber,
      'jobTitle': request.jobTitle,
      'housingAllowance': request.housingAllowance,
      'transportAllowance': request.transportAllowance,
      'paymentFrequency': request.paymentFrequency,
      'paymentMethod': request.paymentMethod,
      'mpesaNumber': request.mpesaNumber,
      'bankName': request.bankName,
      'bankAccount': request.bankAccount,
      'notes': request.notes,
    };
  }

  /// Maps [UpdateWorkerRequest] to API JSON payload.
  ///
  /// Only includes non-null fields to support partial updates.
  Map<String, dynamic> _mapUpdateRequestToJson(UpdateWorkerRequest request) {
    return <String, dynamic>{
      if (request.name != null) 'name': request.name,
      if (request.phoneNumber != null) 'phoneNumber': request.phoneNumber,
      if (request.salaryGross != null) 'salaryGross': request.salaryGross,
      if (request.startDate != null)
        'startDate': request.startDate!.toIso8601String(),
      if (request.dateOfBirth != null)
        'dateOfBirth': request.dateOfBirth!.toIso8601String(),
      if (request.employmentType != null)
        'employmentType': request.employmentType,
      if (request.hourlyRate != null) 'hourlyRate': request.hourlyRate,
      if (request.propertyId != null) 'propertyId': request.propertyId,
      if (request.isActive != null) 'isActive': request.isActive,
      if (request.email != null) 'email': request.email,
      if (request.idNumber != null) 'idNumber': request.idNumber,
      if (request.kraPin != null) 'kraPin': request.kraPin,
      if (request.nssfNumber != null) 'nssfNumber': request.nssfNumber,
      if (request.nhifNumber != null) 'nhifNumber': request.nhifNumber,
      if (request.jobTitle != null) 'jobTitle': request.jobTitle,
      if (request.housingAllowance != null)
        'housingAllowance': request.housingAllowance,
      if (request.transportAllowance != null)
        'transportAllowance': request.transportAllowance,
      if (request.paymentFrequency != null)
        'paymentFrequency': request.paymentFrequency,
      if (request.paymentMethod != null) 'paymentMethod': request.paymentMethod,
      if (request.mpesaNumber != null) 'mpesaNumber': request.mpesaNumber,
      if (request.bankName != null) 'bankName': request.bankName,
      if (request.bankAccount != null) 'bankAccount': request.bankAccount,
      if (request.notes != null) 'notes': request.notes,
    };
  }

  // ---------------------------------------------------------------------------
  // Private Methods: Type Conversion Helpers
  // ---------------------------------------------------------------------------

  /// Converts a dynamic value to double, defaulting to 0.0.
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Converts a dynamic value to nullable double.
  double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

// =============================================================================
// DEFAULTS
// =============================================================================

/// Default values for optional worker fields.
abstract class _Defaults {
  static const String employmentType = 'FIXED';
  static const String paymentFrequency = 'MONTHLY';
  static const String paymentMethod = 'MPESA';
  static const bool isActive = true;
}

// =============================================================================
// EXCEPTIONS
// =============================================================================

/// Exception thrown by [WorkersRepository] operations.
class WorkerRepositoryException implements Exception {
  /// The operation that failed (e.g., 'create worker', 'fetch workers').
  final String operation;

  /// Human-readable error message.
  final String message;

  /// The original error that caused this exception.
  final Object? originalError;

  const WorkerRepositoryException({
    required this.operation,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'Failed to $operation: $message';

  /// Whether this exception was caused by a network error.
  bool get isNetworkError => originalError is DioException;

  /// Whether this exception was caused by a server error (5xx).
  bool get isServerError {
    if (originalError is DioException) {
      final statusCode = (originalError as DioException).response?.statusCode;
      return statusCode != null && statusCode >= 500;
    }
    return false;
  }

  /// Whether this exception was caused by a client error (4xx).
  bool get isClientError {
    if (originalError is DioException) {
      final statusCode = (originalError as DioException).response?.statusCode;
      return statusCode != null && statusCode >= 400 && statusCode < 500;
    }
    return false;
  }

  /// Whether this exception was caused by a not found error (404).
  bool get isNotFound {
    if (originalError is DioException) {
      return (originalError as DioException).response?.statusCode == 404;
    }
    return false;
  }
}

// =============================================================================
// EXTENSIONS
// =============================================================================

/// Extension methods for [List<WorkerModel>].
extension WorkerListExtensions on List<WorkerModel> {
  /// Returns only active workers.
  List<WorkerModel> get active => where((w) => w.isActive).toList();

  /// Returns only terminated workers.
  List<WorkerModel> get terminated => where((w) => !w.isActive).toList();

  /// Returns workers sorted by name alphabetically.
  List<WorkerModel> get sortedByName {
    final copy = List<WorkerModel>.from(this);
    copy.sort((a, b) => a.name.compareTo(b.name));
    return copy;
  }

  /// Returns workers sorted by salary (highest first).
  List<WorkerModel> get sortedBySalaryDesc {
    final copy = List<WorkerModel>.from(this);
    copy.sort((a, b) => b.salaryGross.compareTo(a.salaryGross));
    return copy;
  }

  /// Returns workers filtered by payment method.
  List<WorkerModel> byPaymentMethod(String method) {
    return where((w) => w.paymentMethod == method).toList();
  }

  /// Returns total gross salary for all workers in the list.
  double get totalGrossSalary {
    return fold(0.0, (sum, w) => sum + w.salaryGross);
  }

  /// Returns total monthly payroll cost (salary + allowances).
  double get totalMonthlyCost {
    return fold(0.0, (sum, w) {
      return sum + w.salaryGross + w.housingAllowance + w.transportAllowance;
    });
  }
}