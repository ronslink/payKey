import 'package:dio/dio.dart';
import '../api_service.dart';

// =============================================================================
// WORKER SERVICE EXTENSION
// =============================================================================

/// Extension providing worker-related API operations.
///
/// Usage:
/// ```dart
/// final response = await apiService.workers.getAll();
/// final worker = await apiService.workers.getById('123');
/// ```
extension WorkerService on ApiService {
  /// Access worker endpoints.
  WorkerEndpoints get workers => WorkerEndpoints(this);
}

// =============================================================================
// WORKER ENDPOINTS
// =============================================================================

/// Worker API endpoint operations.
class WorkerEndpoints {
  final ApiService _api;

  const WorkerEndpoints(this._api);

  // ---------------------------------------------------------------------------
  // Read Operations
  // ---------------------------------------------------------------------------

  /// Get all workers.
  ///
  /// Returns list of all workers for the authenticated user.
  /// Uses no-cache headers to ensure fresh data.
  Future<Response> getAll() async {
    return _api.get('/workers', noCache: true);
  }

  /// Get a single worker by ID.
  Future<Response> getById(String workerId) async {
    return _api.get('/workers/$workerId', noCache: true);
  }

  /// Get active workers only.
  Future<Response> getActive() async {
    return _api.get('/workers', queryParams: {'status': 'active'}, noCache: true);
  }

  /// Get terminated/archived workers.
  Future<Response> getArchived() async {
    return _api.get('/workers', queryParams: {'status': 'terminated'}, noCache: true);
  }

  /// Search workers by name or phone.
  Future<Response> search(String query) async {
    return _api.get(
      '/workers/search',
      queryParams: {'q': query},
      noCache: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Write Operations
  // ---------------------------------------------------------------------------

  /// Create a new worker.
  ///
  /// Required fields in [data]: name, phoneNumber, salaryGross, paymentMethod.
  Future<Response> create(Map<String, dynamic> data) async {
    return _api.post('/workers', data: data, noCache: true);
  }

  /// Update an existing worker.
  ///
  /// Only provided fields in [data] will be updated.
  Future<Response> update(String workerId, Map<String, dynamic> data) async {
    return _api.patch('/workers/$workerId', data: data, noCache: true);
  }

  /// Delete a worker.
  ///
  /// Consider using [terminate] instead for audit trail.
  Future<Response> delete(String workerId) async {
    return _api.delete('/workers/$workerId');
  }

  // ---------------------------------------------------------------------------
  // Status Operations
  // ---------------------------------------------------------------------------

  /// Terminate a worker.
  ///
  /// Sets worker status to terminated with optional termination details.
  Future<Response> terminate(
    String workerId, {
    DateTime? terminationDate,
    String? reason,
  }) async {
    return _api.post(
      '/workers/$workerId/terminate',
      data: {
        'terminationDate': (terminationDate ?? DateTime.now()).toIso8601String(),
        if (reason != null) 'reason': reason,
      },
      noCache: true,
    );
  }

  /// Reactivate a terminated worker.
  Future<Response> reactivate(String workerId) async {
    return _api.post('/workers/$workerId/reactivate', noCache: true);
  }

  // ---------------------------------------------------------------------------
  // Bulk Operations
  // ---------------------------------------------------------------------------

  /// Create multiple workers at once.
  Future<Response> createBulk(List<Map<String, dynamic>> workers) async {
    return _api.post('/workers/bulk', data: {'workers': workers}, noCache: true);
  }

  /// Update multiple workers at once.
  Future<Response> updateBulk(List<WorkerBulkUpdate> updates) async {
    return _api.patch(
      '/workers/bulk',
      data: {'updates': updates.map((u) => u.toJson()).toList()},
      noCache: true,
    );
  }

  /// Delete multiple workers.
  Future<Response> deleteBulk(List<String> workerIds) async {
    return _api.delete('/workers/bulk', data: {'workerIds': workerIds});
  }

  // ---------------------------------------------------------------------------
  // Documents & Files
  // ---------------------------------------------------------------------------

  /// Upload a document for a worker.
  Future<Response> uploadDocument(
    String workerId,
    String filePath,
    String documentType,
  ) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromFile(filePath),
      'type': documentType,
    });

    return _api.post(
      '/workers/$workerId/documents',
      data: formData,
      noCache: true,
    );
  }

  /// Get documents for a worker.
  Future<Response> getDocuments(String workerId) async {
    return _api.get('/workers/$workerId/documents', noCache: true);
  }

  // ---------------------------------------------------------------------------
  // Statistics
  // ---------------------------------------------------------------------------

  /// Get worker statistics/summary.
  Future<Response> getStatistics() async {
    return _api.get('/workers/statistics', noCache: true);
  }
}

// =============================================================================
// HELPER TYPES
// =============================================================================

/// Represents a bulk update operation for a worker.
class WorkerBulkUpdate {
  final String workerId;
  final Map<String, dynamic> data;

  const WorkerBulkUpdate({
    required this.workerId,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'id': workerId,
        ...data,
      };
}

// =============================================================================
// WORKER DATA BUILDERS
// =============================================================================

/// Builder for creating worker data payloads.
///
/// Usage:
/// ```dart
/// final data = WorkerDataBuilder()
///   .name('John Doe')
///   .phone('+254712345678')
///   .salary(50000)
///   .paymentMethod(PaymentMethod.mpesa)
///   .build();
/// ```
class WorkerDataBuilder {
  final Map<String, dynamic> _data = {};

  WorkerDataBuilder name(String value) {
    _data['name'] = value;
    return this;
  }

  WorkerDataBuilder phone(String value) {
    _data['phoneNumber'] = value;
    return this;
  }

  WorkerDataBuilder email(String? value) {
    if (value != null) _data['email'] = value;
    return this;
  }

  WorkerDataBuilder idNumber(String? value) {
    if (value != null) _data['idNumber'] = value;
    return this;
  }

  WorkerDataBuilder salary(double value) {
    _data['salaryGross'] = value;
    return this;
  }

  WorkerDataBuilder housingAllowance(double? value) {
    if (value != null) _data['housingAllowance'] = value;
    return this;
  }

  WorkerDataBuilder transportAllowance(double? value) {
    if (value != null) _data['transportAllowance'] = value;
    return this;
  }

  WorkerDataBuilder jobTitle(String? value) {
    if (value != null) _data['jobTitle'] = value;
    return this;
  }

  WorkerDataBuilder paymentMethod(String value) {
    _data['paymentMethod'] = value;
    return this;
  }

  WorkerDataBuilder paymentFrequency(String value) {
    _data['paymentFrequency'] = value;
    return this;
  }

  WorkerDataBuilder employmentType(String value) {
    _data['employmentType'] = value;
    return this;
  }

  WorkerDataBuilder startDate(DateTime value) {
    _data['startDate'] = value.toIso8601String();
    return this;
  }

  WorkerDataBuilder kraPin(String? value) {
    if (value != null) _data['kraPin'] = value;
    return this;
  }

  WorkerDataBuilder nhifNumber(String? value) {
    if (value != null) _data['nhifNumber'] = value;
    return this;
  }

  WorkerDataBuilder nssfNumber(String? value) {
    if (value != null) _data['nssfNumber'] = value;
    return this;
  }

  WorkerDataBuilder bankName(String? value) {
    if (value != null) _data['bankName'] = value;
    return this;
  }

  WorkerDataBuilder bankAccountNumber(String? value) {
    if (value != null) _data['bankAccountNumber'] = value;
    return this;
  }

  WorkerDataBuilder notes(String? value) {
    if (value != null) _data['notes'] = value;
    return this;
  }

  WorkerDataBuilder custom(String key, dynamic value) {
    if (value != null) _data[key] = value;
    return this;
  }

  /// Build the worker data map.
  Map<String, dynamic> build() => Map.unmodifiable(_data);

  /// Validate required fields are present.
  List<String> validate() {
    final errors = <String>[];

    if (!_data.containsKey('name') || (_data['name'] as String).isEmpty) {
      errors.add('Name is required');
    }

    if (!_data.containsKey('phoneNumber') ||
        (_data['phoneNumber'] as String).isEmpty) {
      errors.add('Phone number is required');
    }

    if (!_data.containsKey('salaryGross')) {
      errors.add('Salary is required');
    }

    if (!_data.containsKey('paymentMethod')) {
      errors.add('Payment method is required');
    }

    return errors;
  }

  /// Build if valid, otherwise throw.
  Map<String, dynamic> buildOrThrow() {
    final errors = validate();
    if (errors.isNotEmpty) {
      throw ArgumentError('Invalid worker data: ${errors.join(', ')}');
    }
    return build();
  }
}