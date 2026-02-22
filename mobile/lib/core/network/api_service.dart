import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/api_constants.dart';

/// Provider for the singleton ApiService instance
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// =============================================================================
// API SERVICE - CORE
// =============================================================================

/// Main API service singleton that handles HTTP requests and authentication.
/// 
/// Usage:
/// ```dart
/// final api = ApiService();
/// final response = await api.workers.getAll();
/// ```
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _initializeDio();
    _initializeEndpoints();
  }

  // ---------------------------------------------------------------------------
  // Public Properties
  // ---------------------------------------------------------------------------

  final Dio dio = Dio();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  static String get baseUrl => ApiConstants.baseUrl;

  // Endpoint accessors
  late final AuthEndpoints auth;

  late final PayrollEndpoints payroll;
  late final PayPeriodEndpoints payPeriods;
  late final TaxEndpoints taxes;
  late final PaymentEndpoints payments;
  late final SubscriptionEndpoints subscriptions;
  late final AccountingEndpoints accounting;
  late final LeaveEndpoints leave;
  late final WorkerEndpoints workers;
  late final ReportEndpoints reports;
  late final EmployeePortalEndpoints employeePortal;
  late final TimeTrackingEndpoints timeTracking;
  late final PropertyEndpoints properties;
  late final WorkersConvertEndpoints workersConvert;
  late final UploadEndpoints uploads;
  late final GovEndpoints gov;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  void _initializeDio() {
    dio.options
      ..baseUrl = baseUrl
      ..connectTimeout = const Duration(seconds: 30)
      ..receiveTimeout = const Duration(seconds: 30)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });

    dio.interceptors.add(_createAuthInterceptor());
  }

  void _initializeEndpoints() {
    auth = AuthEndpoints(this);

    payroll = PayrollEndpoints(this);
    payPeriods = PayPeriodEndpoints(this);
    taxes = TaxEndpoints(this);
    payments = PaymentEndpoints(this);
    subscriptions = SubscriptionEndpoints(this);
    accounting = AccountingEndpoints(this);
    leave = LeaveEndpoints(this);
    workers = WorkerEndpoints(this);
    reports = ReportEndpoints(this);
    employeePortal = EmployeePortalEndpoints(this);
    timeTracking = TimeTrackingEndpoints(this);
    properties = PropertyEndpoints(this);
    workersConvert = WorkersConvertEndpoints(this);
    uploads = UploadEndpoints(this);
    gov = GovEndpoints(this);
  }

  InterceptorsWrapper _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        debugPrint('API Request: ${options.method} ${options.uri}');
        if (!_isAuthEndpoint(options.uri.path)) {
          final token = await _getStoredToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            _addNoCacheHeaders(options.headers);
          }
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await clearToken();
          // TODO: Navigate to login page or emit auth state change
        }
        return handler.next(error);
      },
    );
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') || 
           path.contains('/auth/register') ||
           path.contains('/countries');
  }

  Future<String?> _getStoredToken() async {
    try {
      return await secureStorage.read(key: 'access_token');
    } catch (_) {
      return null;
    }
  }

  void _addNoCacheHeaders(Map<String, dynamic> headers) {
    headers.addAll({
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    });
  }

  // ---------------------------------------------------------------------------
  // Generic HTTP Methods
  // ---------------------------------------------------------------------------

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Options? options,
    bool noCache = false,
  }) async {
    return dio.get(
      path,
      queryParameters: queryParams,
      options: noCache ? _withNoCache(options) : options,
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
    bool noCache = false,
  }) async {
    return dio.post(
      path,
      data: data,
      queryParameters: queryParams,
      options: noCache ? _withNoCache(options) : options,
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
    bool noCache = false,
  }) async {
    return dio.patch(
      path,
      data: data,
      queryParameters: queryParams,
      options: noCache ? _withNoCache(options) : options,
    );
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
  }) async {
    return dio.delete(path, data: data, queryParameters: queryParams, options: options);
  }

  Options _withNoCache(Options? base) {
    final headers = <String, dynamic>{
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };

    if (base != null) {
      return base.copyWith(headers: {...?base.headers, ...headers});
    }
    return Options(headers: headers);
  }

  // ---------------------------------------------------------------------------
  // Token Management
  // ---------------------------------------------------------------------------

  Future<void> saveToken(String token) async {
    await secureStorage.write(key: 'access_token', value: token);
  }

  Future<void> clearToken() async {
    await secureStorage.delete(key: 'access_token');
  }

  Future<String?> getToken() async {
    return secureStorage.read(key: 'access_token');
  }

  // ---------------------------------------------------------------------------
  // Error Handling
  // ---------------------------------------------------------------------------

  /// Extracts a human-readable error message from an error.
  String getErrorMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'] as String;
      }
      if (data != null) {
        return data.toString();
      }
      return error.message ?? 'Network error occurred';
    }
    return error.toString();
  }

  /// Wraps an error in an Exception with a readable message.
  /// Wraps an error in an Exception with a readable message.
  Exception handleError(dynamic error) {
    if (error is DioException) {
      return ApiException(
        getErrorMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
    return ApiException(getErrorMessage(error));
  }

  // ---------------------------------------------------------------------------
  // Legacy Methods (for backward compatibility)
  // ---------------------------------------------------------------------------

  // These delegate to the new endpoint classes for backward compatibility.
  // Consider deprecating these in favor of the endpoint accessors.

  Future<Response> login(String email, String password) =>
      auth.login(email, password);

  Future<Response> register(String email, String password,
          {String? firstName, String? lastName}) =>
      auth.register(email, password, firstName: firstName, lastName: lastName);

  Future<Response> getWorkers() => workers.getAll();
  Future<Response> createWorker(Map<String, dynamic> data) => workers.create(data);
  Future<Response> updateWorker(String id, Map<String, dynamic> data) =>
      workers.update(id, data);
  Future<Response> deleteWorker(String id) => workers.delete(id);

  Future<Response> getPayPeriods() => payPeriods.getAll();
  Future<Response> getPayPeriodById(String id) => payPeriods.getById(id);
  Future<Response> createPayPeriod(Map<String, dynamic> data) => payPeriods.create(data);
  Future<Response> updatePayPeriod(String id, Map<String, dynamic> data) =>
      payPeriods.update(id, data);
  Future<Response> deletePayPeriod(String id) => payPeriods.delete(id);
  Future<Response> activatePayPeriod(String id) => payPeriods.activate(id);
  Future<Response> processPayPeriod(String id) => payPeriods.process(id);
  Future<Response> completePayPeriod(String id) => payPeriods.complete(id);
  Future<Response> closePayPeriod(String id) => payPeriods.close(id);
  Future<Response> getPayPeriodStatistics(String id) => payPeriods.getStatistics(id);
  Future<Response> getCurrentPayPeriod() => payPeriods.getCurrent();

  Future<Response> saveDraftPayroll(String payPeriodId, List<Map<String, dynamic>> items) =>
      payroll.saveDraft(payPeriodId, items);
  Future<Response> updatePayrollItem(String id, Map<String, dynamic> updates) =>
      payroll.updateItem(id, updates);
  Future<Response> getDraftPayroll(String payPeriodId) => payroll.getDraft(payPeriodId);
  Future<Response> finalizePayroll(String payPeriodId) => payroll.finalize(payPeriodId);
  Future<List<int>> downloadPayslip(String payrollRecordId) =>
      payroll.downloadPayslip(payrollRecordId);

  Future<Response> calculateTax(double grossSalary) => taxes.calculate(grossSalary);
  Future<Response> getTaxSubmissions() => taxes.getSubmissions();
  Future<Response> markTaxAsFiled(String id) => taxes.markAsFiled(id);
  Future<Response> getCurrentTaxTable() => taxes.getCurrentTable();
  Future<Response> getComplianceStatus() => taxes.getComplianceStatus();
  Future<Response> getTaxDeadlines() => taxes.getDeadlines();

  Future<Response> exportPayrollToCSV(String payPeriodId) =>
      accounting.exportToCSV(payPeriodId);

  Future<Response> getRecentActivities({int limit = 10}) =>
      get('/activities/recent', queryParams: {'limit': limit});

  // ---------------------------------------------------------------------------
  // Account Mappings (Accounting)
  // ---------------------------------------------------------------------------

  Future<Response> getAccountMappings() => accounting.getMappings();

  Future<Response> saveAccountMappings(Map<String, dynamic> mappings) =>
      accounting.saveMappings(mappings);

  // ---------------------------------------------------------------------------
  // Leave Management
  // ---------------------------------------------------------------------------

  Future<Response> getLeaveRequests() => leave.getAll();

  Future<Response> getWorkerLeaveRequests(String workerId) => leave.getByWorker(workerId);

  Future<Response> createLeaveRequest(String workerId, Map<String, dynamic> data) =>
      leave.create(workerId, data);

  Future<Response> updateLeaveRequest(String leaveRequestId, Map<String, dynamic> data) =>
      leave.update(leaveRequestId, data);

  Future<Response> deleteLeaveRequest(String leaveRequestId) => leave.delete(leaveRequestId);

  Future<Response> approveLeaveRequest(String leaveRequestId, bool approved, {String? comments}) =>
      leave.approve(leaveRequestId, approved, comments: comments);

  Future<Response> getLeaveBalance(String workerId) => leave.getBalance(workerId);

  // ---------------------------------------------------------------------------
  // Payroll Records
  // ---------------------------------------------------------------------------

  Future<Response> getPayrollRecords() => payroll.getRecords();

  Future<Response> updatePayrollStatus(String id, String status, {String? paymentDate}) =>
      payroll.updateStatus(id, status, paymentDate: paymentDate);

  Future<Response> deletePayrollRecord(String id) => payroll.deleteRecord(id);

  // ---------------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------------

  Future<Response> getTransactions() => payments.getTransactions();

  Future<Response> getTransactionById(String id) => payments.getTransactionById(id);

  // ---------------------------------------------------------------------------
  // Payments Dashboard
  // ---------------------------------------------------------------------------

  Future<Response> getPaymentDashboard() => payments.getDashboard();

  Future<Response> getPaymentMethods() => payments.getMethods();

  Future<Response> getTaxPaymentSummary() => payments.getTaxPaymentSummary();

  Future<Response> initiateMpesaTopup(
    String phoneNumber, 
    double amount, {
    String? accountReference, 
    String? transactionDesc,
  }) =>
      payments.initiateMpesaTopup(
        phoneNumber, 
        amount,
        accountReference: accountReference,
        transactionDesc: transactionDesc,
      );

  Future<Response> recordTaxPayment({
    required String taxType,
    required double amount,
    required String reference,
    String? paymentDate,
  }) =>
      payments.recordTaxPayment(
        taxType: taxType,
        amount: amount,
        reference: reference,
        paymentDate: paymentDate,
      );

  // ---------------------------------------------------------------------------
  // Subscriptions
  // ---------------------------------------------------------------------------

  Future<Response> getSubscriptionPlans() => subscriptions.getPlans();

  Future<Response> getUserSubscription() => subscriptions.getCurrent();

  Future<Response> getSubscriptionPaymentHistory({
    int? page,
    int? limit,
    String? status,
    String? startDate,
    String? endDate,
  }) =>
      subscriptions.getPaymentHistory(
        page: page,
        limit: limit,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );

  // ---------------------------------------------------------------------------
  // Countries (Public)
  // ---------------------------------------------------------------------------

  Future<Response> getCountries() => get('/countries');

  // ---------------------------------------------------------------------------
  // Tax Submissions
  // ---------------------------------------------------------------------------

  Future<Response> markTaxSubmissionAsFiled(String id) => taxes.markAsFiled(id);

  Future<Response> generateTaxSubmission(String payPeriodId) => taxes.generateSubmission(payPeriodId);

  Future<Response> getMonthlyTaxSummary(int year, int month) => taxes.getMonthlySummary(year, month);

  Future<Response> recordTaxPaymentTax(String id) => taxes.updatePaymentStatus(id, 'paid');

  Future<Response> getTaxPaymentHistory() => taxes.getPaymentHistory();

  Future<Response> getPendingTaxPayments() => taxes.getPendingPayments();

  Future<Response> updateTaxPaymentStatus(String id, String status) => taxes.updatePaymentStatus(id, status);

  Future<Response> getTaxPaymentInstructions() => taxes.getPaymentInstructions();

  // ---------------------------------------------------------------------------
  // Workers (delegates to workers property)
  // ---------------------------------------------------------------------------

  Future<Response> updateUserProfile(Map<String, dynamic> data) => auth.updateProfile(data);

  // ---------------------------------------------------------------------------
  // Worker Import (Excel Upload)
  // ---------------------------------------------------------------------------

  /// Upload Excel file to import workers (GOLD/PLATINUM only)
  Future<Map<String, dynamic>> uploadWorkerExcel(List<int> bytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await dio.post('/excel-import/employees', data: formData);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Download worker import template Excel file
  Future<List<int>> downloadWorkerTemplate() async {
    try {
      final response = await dio.get<List<int>>(
        '/excel-import/employees/template',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );
      return response.data ?? [];
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Download a file from a URL as bytes
  Future<List<int>> downloadFile(String url) async {
    try {
      final response = await dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );
      return response.data ?? [];
    } catch (e) {
      throw handleError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Bank Codes (for PesaLink transfers)
  // ---------------------------------------------------------------------------

  /// Get list of supported Kenyan banks for bank transfers
  Future<List<Map<String, dynamic>>> getBanks() async {
    try {
      final response = await dio.get('/payments/intasend/banks');
      if (response.data is List) {
        return (response.data as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw handleError(e);
    }
  }
}

// =============================================================================
// ENDPOINT CLASSES
// =============================================================================

/// Base class for endpoint groups.
abstract class BaseEndpoints {
  final ApiService _api;
  const BaseEndpoints(this._api);
}

// -----------------------------------------------------------------------------
// Auth Endpoints
// -----------------------------------------------------------------------------

class AuthEndpoints extends BaseEndpoints {
  const AuthEndpoints(super.api);

  Future<Response> login(String email, String password) {
    return _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> register(
    String email,
    String password, {
    String? firstName,
    String? lastName,
  }) {
    return _api.post('/auth/register', data: {
      'email': email,
      'password': password,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
    });
  }

  Future<Response> socialLogin({
    required String provider,
    required String token,
    required String email,
    String? firstName,
    String? lastName,
    String? photoUrl,
  }) {
    return _api.post('/auth/social', data: {
      'provider': provider,
      'token': token,
      'email': email,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });
  }

  Future<Response> updateProfile(Map<String, dynamic> data) {
    return _api.patch('/users/profile', data: data);
  }
}
// -----------------------------------------------------------------------------
// Worker Endpoints
// -----------------------------------------------------------------------------

class WorkerEndpoints extends BaseEndpoints {
  const WorkerEndpoints(super.api);

  Future<Response> getAll() => _api.get('/workers');

  Future<Response> getById(String id) => _api.get('/workers/$id');

  Future<Response> create(Map<String, dynamic> data) => _api.post('/workers', data: data);

  Future<Response> update(String id, Map<String, dynamic> data) => _api.patch('/workers/$id', data: data);

  Future<Response> delete(String id) => _api.delete('/workers/$id');

  Future<Response> terminate(String id, Map<String, dynamic> data) => _api.post('/workers/$id/terminate', data: data);

  Future<Response> getTerminationHistory() => _api.get('/workers/terminated/history');

  Future<Response> getArchived() => _api.get('/workers/archived');

  Future<Response> restore(String id) => _api.post('/workers/$id/restore');

  // Document endpoints
  Future<Response> getDocuments(String workerId) => _api.get('/workers/$workerId/documents');

  Future<Response> uploadDocument(
    String workerId, 
    List<int> bytes, 
    String filename, {
    String type = 'OTHER',
    String? notes,
    String? expiresAt,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes, 
        filename: filename,
        contentType: MediaType.parse(_getMimeType(filename)),
      ),
      'type': type,
      if (notes != null) 'notes': notes,
      if (expiresAt != null) 'expiresAt': expiresAt,
    });
    return _api.post('/workers/$workerId/documents', data: formData);
  }

  Future<Response> deleteDocument(String documentId) => _api.delete('/workers/documents/$documentId');

  String _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default: return 'application/octet-stream';
    }
  }
}



// -----------------------------------------------------------------------------
// Payroll Endpoints
// -----------------------------------------------------------------------------

class PayrollEndpoints extends BaseEndpoints {
  const PayrollEndpoints(super.api);

  Future<Response> getStats() => _api.get('/payroll/stats');

  Future<Response> calculate({List<String>? workerIds}) {
    return _api.post('/payroll/calculate', data: {
      if (workerIds != null) 'workerIds': workerIds,
    });
  }

  Future<Response> process(List<String> workerIds, {required String payPeriodId}) {
    return _api.post('/payroll/process', data: {
      'workerIds': workerIds,
      'payPeriodId': payPeriodId,
    });
  }

  Future<Response> saveDraft(String payPeriodId, List<Map<String, dynamic>> items) {
    return _api.post('/payroll/draft', data: {
      'payPeriodId': payPeriodId,
      'payrollItems': items,
    });
  }

  Future<Response> getDraft(String payPeriodId) {
    return _api.get('/payroll/draft/$payPeriodId');
  }

  Future<Response> updateItem(String id, Map<String, dynamic> updates) {
    return _api.patch('/payroll/draft/$id', data: updates);
  }

  Future<Response> finalize(String payPeriodId) {
    return _api.post('/payroll/finalize/$payPeriodId');
  }

  Future<Response> getRecords() => _api.get('/payroll-records');

  Future<Response> updateStatus(String id, String status, {String? paymentDate}) {
    return _api.patch('/payroll-records/$id/status', data: {
      'status': status,
      if (paymentDate != null) 'paymentDate': paymentDate,
    });
  }

  Future<Response> deleteRecord(String id) => _api.delete('/payroll-records/$id');

  Future<List<int>> downloadPayslip(String payrollRecordId) async {
    try {
      final response = await _api.dio.get<List<int>>(
        '/payroll/payslip/$payrollRecordId',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );
      return response.data ?? [];
    } catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Get payslips for a specific worker
  Future<Response> getPayslipsForWorker(String workerId) {
    return _api.get('/payroll-records/worker/$workerId');
  }
}

// -----------------------------------------------------------------------------
// Pay Period Endpoints
// -----------------------------------------------------------------------------

class PayPeriodEndpoints extends BaseEndpoints {
  const PayPeriodEndpoints(super.api);

  Future<Response> getAll({Map<String, dynamic>? queryParams}) => _api.get('/pay-periods', queryParams: queryParams);

  Future<Response> getById(String id) => _api.get('/pay-periods/$id');

  Future<Response> getByStatus(String status) {
    return _api.get('/pay-periods', queryParams: {'status': status, 'limit': 100});
  }

  Future<Response> getCurrent() => _api.get('/pay-periods/current');

  Future<Response> getStatistics(String id) => _api.get('/pay-periods/$id/statistics');

  Future<Response> create(Map<String, dynamic> data) {
    return _api.post('/pay-periods', data: data);
  }

  Future<Response> update(String id, Map<String, dynamic> data) {
    return _api.patch('/pay-periods/$id', data: data);
  }

  Future<Response> delete(String id) => _api.delete('/pay-periods/$id');

  Future<Response> updateStatus(String id, String action) {
    return _api.patch('/pay-periods/$id/status', data: {'action': action});
  }

  // Status transitions
  Future<Response> activate(String id) => _api.post('/pay-periods/$id/activate');
  Future<Response> process(String id) => _api.post('/pay-periods/$id/process');
  Future<Response> complete(String id) => _api.post('/pay-periods/$id/complete');
  Future<Response> close(String id) => _api.post('/pay-periods/$id/close');
  Future<Response> reopen(String id) => _api.post('/pay-periods/$id/reopen');

  Future<Response> generatePayslips(String id) {
    return _api.post('/pay-periods/$id/payslips');
  }

  Future<Response> generate({
    required String frequency,
    required String startDate,
    required String endDate,
  }) {
    return _api.post('/pay-periods/generate', data: {
      'frequency': frequency,
      'startDate': startDate,
      'endDate': endDate,
    });
  }
}

// -----------------------------------------------------------------------------
// Tax Endpoints
// -----------------------------------------------------------------------------

class TaxEndpoints extends BaseEndpoints {
  const TaxEndpoints(super.api);

  Future<Response> calculate(double grossSalary) {
    return _api.post('/taxes/calculate', data: {'grossSalary': grossSalary});
  }

  Future<Response> getCurrentTable() => _api.get('/taxes/current');

  Future<Response> getComplianceStatus() => _api.get('/taxes/compliance');

  Future<Response> getDeadlines() => _api.get('/taxes/deadlines');

  // Submissions
  Future<Response> getSubmissions() => _api.get('/taxes/submissions');

  Future<Response> getMonthlySummaries() => _api.get('/taxes/submissions/monthly');

  Future<Response> markMonthAsFiled(int year, int month) {
    return _api.post('/taxes/submissions/monthly/file', data: {
      'year': year,
      'month': month,
    });
  }

  Future<Response> exportStatutoryReturn({
    required String exportType,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _api.post('/export', data: {
      'exportType': exportType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    });
  }

  Future<Response> downloadExport(String maxId) {
    // This returns the binary stream directly or a temporary link?
    // Controller returns StreamableFile, so we might need special handling if using Dio to download.
    // However, usually we get a downloadUrl. This method might be for metadata or direct stream.
    // The controller returns StreamableFile on /export/download/:id
    return _api.get(
      '/export/download/$maxId',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': '*/*'},
      ),
    );
  }

  Future<Response> getSubmissionByPeriod(String payPeriodId) {
    return _api.get('/taxes/submissions/period/$payPeriodId');
  }

  Future<Response> generateSubmission(String payPeriodId) {
    return _api.post('/taxes/submissions/generate', data: {'payPeriodId': payPeriodId});
  }

  Future<Response> markAsFiled(String id) {
    return _api.patch('/taxes/submissions/$id/file');
  }

  // Tax Payments
  Future<Response> getMonthlySummary(int year, int month) {
    return _api.get('/tax-payments/summary/$year/$month');
  }

  Future<Response> getPaymentHistory() => _api.get('/tax-payments/history');

  Future<Response> getPendingPayments() => _api.get('/tax-payments/pending');

  Future<Response> updatePaymentStatus(String id, String status) {
    return _api.patch('/tax-payments/$id/status', data: {'status': status});
  }

  Future<Response> getPaymentInstructions() => _api.get('/tax-payments/instructions');
}

// -----------------------------------------------------------------------------
// Payment Endpoints
// -----------------------------------------------------------------------------

class PaymentEndpoints extends BaseEndpoints {
  const PaymentEndpoints(super.api);

  // Dashboard
  Future<Response> getDashboard() => _api.get('/payments/unified/dashboard');

  Future<Response> getWalletBalance() => _api.get('/payments/unified/wallet');

  Future<Response> getMethods() => _api.get('/payments/unified/methods');

  // M-Pesa
  Future<Response> initiateMpesaTopup(String phoneNumber, double amount, {String? accountReference, String? transactionDesc}) {
    return _api.post('/payments/unified/mpesa/topup', data: {
      'phoneNumber': phoneNumber,
      'amount': amount,
      if (accountReference != null) 'accountReference': accountReference,
      if (transactionDesc != null) 'transactionDesc': transactionDesc,
    });
  }

  /// Alias for [initiateMpesaTopup] (legacy support).
  Future<Response> initiateStkPush(String phoneNumber, double amount) {
    return initiateMpesaTopup(phoneNumber, amount);
  }

  Future<Response> sendB2C({
    required String transactionId,
    required String phoneNumber,
    required double amount,
    required String remarks,
  }) {
    return _api.post('/payments/send-b2c', data: {
      'transactionId': transactionId,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'remarks': remarks,
    });
  }

  // Tax Payments
  Future<Response> getTaxPaymentSummary() {
    return _api.get('/payments/unified/tax-payments/summary');
  }

  Future<Response> recordTaxPayment({
    required String taxType,
    required double amount,
    required String reference,
    String? paymentDate,
  }) {
    return _api.post('/payments/unified/tax-payments/record', data: {
      'taxType': taxType,
      'amount': amount,
      'reference': reference,
      if (paymentDate != null) 'paymentDate': paymentDate,
    });
  }

  // Transactions
  Future<Response> getTransactions() => _api.get('/transactions');

  Future<Response> getTransactionById(String id) => _api.get('/transactions/$id');

  // Checkout
  Future<Response> initiateCheckout(double amount) {
    return _api.post('/payments/checkout/topup', data: {'amount': amount});
  }
}

// -----------------------------------------------------------------------------
// Upload Endpoints
// -----------------------------------------------------------------------------

class UploadEndpoints extends BaseEndpoints {
  const UploadEndpoints(super.api);

  Future<String> uploadAvatar(List<int> bytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _api.post('/uploads/avatar', data: formData);
      return response.data['url'] as String;
    } catch (e) {
      throw _api.handleError(e);
    }
  }
}

// -----------------------------------------------------------------------------
// Government Integration Endpoints
// -----------------------------------------------------------------------------

class GovEndpoints extends BaseEndpoints {
  const GovEndpoints(super.api);

  Future<Response> getSubmissions() => _api.get('/gov/submissions');

  Future<Response> getSubmission(String id) => _api.get('/gov/submissions/$id');

  Future<Response> generateKraP10(String payPeriodId) {
    return _api.post('/gov/kra/generate', data: {'payPeriodId': payPeriodId});
  }

  Future<Response> generateShif(String payPeriodId) {
    return _api.post('/gov/shif/generate', data: {'payPeriodId': payPeriodId});
  }

  Future<Response> generateNssf(String payPeriodId) {
    return _api.post('/gov/nssf/generate', data: {'payPeriodId': payPeriodId});
  }

  Future<List<int>> downloadFile(String submissionId) async {
    try {
      final response = await _api.dio.get<List<int>>(
        '/gov/submissions/$submissionId/download',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );
      return response.data ?? [];
    } catch (e) {
      throw _api.handleError(e);
    }
  }

  Future<Response> markAsUploaded(String submissionId) {
    return _api.patch('/gov/submissions/$submissionId/uploaded');
  }

  Future<Response> confirmSubmission(String submissionId, String referenceNumber, {String? notes}) {
    return _api.patch('/gov/submissions/$submissionId/confirm', data: {
      'referenceNumber': referenceNumber,
      if (notes != null) 'notes': notes,
    });
  }
}

// -----------------------------------------------------------------------------
// Subscription Endpoints
// -----------------------------------------------------------------------------

class SubscriptionEndpoints extends BaseEndpoints {
  const SubscriptionEndpoints(super.api);

  Future<Response> getPlans() => _api.get('/subscriptions/plans', noCache: true);

  Future<Response> getCurrent() => _api.get('/subscriptions/current', noCache: true);

  Future<Response> getUsage() => _api.get('/subscriptions/usage', noCache: true);

  Future<Response> subscribe(String planId) {
    return _api.post('/subscriptions/subscribe', data: {'planId': planId});
  }

  Future<Response> subscribeWithStripe(String planId) {
    return _api.post('/payments/unified/subscribe', data: {
      'planId': planId,
      'paymentMethod': 'stripe',
    });
  }

  Future<Response> cancel(String subscriptionId) {
    return _api.post('/subscriptions/$subscriptionId/cancel');
  }

  Future<Response> resume(String subscriptionId) {
    return _api.post('/subscriptions/$subscriptionId/resume');
  }

  Future<Response> upgrade(String subscriptionId, String newPlanId) {
    return _api.post('/subscriptions/$subscriptionId/upgrade', data: {
      'newPlanId': newPlanId,
    });
  }

  Future<Response> update(String subscriptionId, Map<String, dynamic> updates) {
    return _api.patch('/subscriptions/$subscriptionId', data: updates);
  }

  Future<Response> getPaymentHistory({
    int? page,
    int? limit,
    String? status,
    String? startDate,
    String? endDate,
  }) {
    final queryParams = <String, dynamic>{
      if (page != null) 'page': page.toString(),
      if (limit != null) 'limit': limit.toString(),
      if (status != null) 'status': status,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };

    return _api.get(
      '/subscriptions/subscription-payment-history',
      queryParams: queryParams.isEmpty ? null : queryParams,
      noCache: true,
    );
  }
}

// -----------------------------------------------------------------------------
// Accounting Endpoints
// -----------------------------------------------------------------------------

class AccountingEndpoints extends BaseEndpoints {
  const AccountingEndpoints(super.api);

  Future<Response> exportToCSV(String payPeriodId) {
    return _api.post('/accounting/export/$payPeriodId', data: {'format': 'CSV'});
  }

  Future<Response> getJournalEntries(String payPeriodId) {
    return _api.post('/accounting/journal-entries/$payPeriodId');
  }

  Future<Response> getFormats() => _api.get('/accounting/formats');

  Future<Response> getMappings() => _api.get('/accounting/mappings');

  Future<Response> saveMappings(Map<String, dynamic> mappings) {
    return _api.post('/accounting/mappings', data: mappings);
  }
}

// -----------------------------------------------------------------------------
// Leave Endpoints
// -----------------------------------------------------------------------------

class LeaveEndpoints extends BaseEndpoints {
  const LeaveEndpoints(super.api);

  Future<Response> getAll() => _api.get('/workers/leave-requests');

  Future<Response> getByWorker(String workerId) {
    return _api.get('/workers/$workerId/leave-requests');
  }

  Future<Response> getBalance(String workerId) {
    return _api.get('/workers/$workerId/leave-balance');
  }

  Future<Response> create(String workerId, Map<String, dynamic> data) {
    return _api.post('/workers/$workerId/leave-requests', data: data);
  }

  Future<Response> update(String leaveRequestId, Map<String, dynamic> data) {
    return _api.patch('/workers/leave-requests/$leaveRequestId', data: data);
  }

  Future<Response> delete(String leaveRequestId) {
    return _api.delete('/workers/leave-requests/$leaveRequestId');
  }

  Future<Response> approve(String leaveRequestId, bool approved, {String? comments}) {
    return _api.patch('/workers/leave-requests/$leaveRequestId/approve', data: {
      'approved': approved,
      // Backend DTO field is 'rejectionReason', not 'comments'
      if (comments != null && comments.isNotEmpty) 'rejectionReason': comments,
    });
  }
  }


// -----------------------------------------------------------------------------
// Report Endpoints
// -----------------------------------------------------------------------------

class ReportEndpoints extends BaseEndpoints {
  const ReportEndpoints(super.api);

  Future<Response> getPayrollSummary(String payPeriodId) {
    return _api.get('/reports/payroll-summary', queryParams: {'payPeriodId': payPeriodId});
  }

  Future<Response> getStatutoryReport(String payPeriodId) {
    return _api.get('/reports/statutory', queryParams: {'payPeriodId': payPeriodId});
  }

  Future<Response> getMusterRoll(String payPeriodId) {
    return _api.get('/reports/muster-roll', queryParams: {'payPeriodId': payPeriodId});
  }

  Future<Response> getTaxSummary(int year) {
    return _api.get('/reports/tax', queryParams: {'year': year.toString()});
  }

  Future<Response> getDashboardMetrics() => _api.get('/reports/dashboard');

  /// Get P9 reports for all workers for a given year
  Future<Response> getP9Reports(int year, {String? workerId}) {
    final queryParams = {'year': year.toString()};
    if (workerId != null) {
      queryParams['workerId'] = workerId;
    }
    return _api.get('/reports/p9', queryParams: queryParams);
  }

  /// Get P10 report (annual employer return)
  Future<Response> getP10Report(int year) {
    return _api.get('/reports/p10', queryParams: {'year': year.toString()});
  }

  /// Download P9 ZIP file containing all worker P9 PDFs
  Future<List<int>> downloadP9Zip(int year) async {
    try {
      final response = await _api.dio.get<List<int>>(
        '/reports/p9/zip',
        queryParameters: {'year': year.toString()},
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );
      return response.data ?? [];
    } catch (e) {
      throw _api.handleError(e);
    }
  }
  Future<List<int>> downloadPayslipPdf(String recordId) async {
    try {
      final response = await _api.dio.get<List<int>>(
        '/reports/payslip/$recordId/pdf',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );
      return response.data ?? [];
    } catch (e) {
      throw _api.handleError(e);
    }
  }

  Future<List<int>> downloadStatutoryPdf(String payPeriodId) async {
    try {
      final response = await _api.dio.get<List<int>>(
        '/reports/statutory/$payPeriodId/pdf',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );
      return response.data ?? [];
    } catch (e) {
      throw _api.handleError(e);
    }
  }
}

// -----------------------------------------------------------------------------
// Employee Portal Endpoints
// -----------------------------------------------------------------------------

class EmployeePortalEndpoints extends BaseEndpoints {
  const EmployeePortalEndpoints(super.api);

  /// Employee claims their account using phone + invite code + PIN (public)
  Future<Response> claimAccount({
    required String phoneNumber,
    required String inviteCode,
    required String pin,
  }) {
    return _api.post('/employee-portal/claim-account', data: {
      'phoneNumber': phoneNumber,
      'inviteCode': inviteCode,
      'pin': pin,
    });
  }

  /// Employee login with phone + PIN (public)
  Future<Response> employeeLogin({
    required String phoneNumber,
    required String pin,
  }) {
    return _api.post('/employee-portal/login', data: {
      'phoneNumber': phoneNumber,
      'pin': pin,
    });
  }

  /// Employer generates invite code for a worker
  Future<Response> generateInvite(String workerId) {
    return _api.post('/employee-portal/invite/$workerId');
  }

  /// Check if worker has been invited or has account
  Future<Response> checkInviteStatus(String workerId) {
    return _api.get('/employee-portal/invite-status/$workerId');
  }

  /// Employee: Get own profile
  Future<Response> getMyProfile() => _api.get('/employee-portal/my-profile');

  /// Employee: Get assigned property (Gold/Platinum only)
  /// Returns property details for clock-in location display
  Future<Response> getMyProperty() => _api.get('/employee-portal/my-property');

  /// Employee: Get all employer properties for clock-in selection (Gold/Platinum only)
  Future<Response> getEmployerProperties() => _api.get('/employee-portal/employer-properties');

  /// Employee: Get own leave balance
  Future<Response> getMyLeaveBalance() => _api.get('/employee-portal/my-leave-balance');

  /// Employee: Get own leave requests
  Future<Response> getMyLeaveRequests() => _api.get('/employee-portal/my-leave-requests');

  /// Employee: Request leave
  Future<Response> requestLeave({
    required String leaveType,
    required String startDate,
    required String endDate,
    String? reason,
  }) {
    return _api.post('/employee-portal/request-leave', data: {
      'leaveType': leaveType,
      'startDate': startDate,
      'endDate': endDate,
      if (reason != null) 'reason': reason,
    });
  }

  /// Employee: Cancel leave request
  Future<Response> cancelLeaveRequest(String requestId) {
    return _api.post('/employee-portal/cancel-leave/$requestId');
  }

  /// Employee: Get own P9 tax report for a given year
  Future<Response> getMyP9Report(int year) {
    return _api.get('/reports/my-p9', queryParams: {'year': year.toString()});
  }

  /// Employee: Download own P9 as PDF
  Future<List<int>> downloadMyP9Pdf(int year) async {
    try {
      final response = await _api.dio.get<List<int>>(
        '/reports/my-p9/pdf',
        queryParameters: {'year': year.toString()},
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );
      return response.data ?? [];
    } catch (e) {
      throw _api.handleError(e);
    }
  }
  /// Employee: Update payment details
  Future<Response> updatePaymentDetails(Map<String, dynamic> data) {
    return _api.patch('/employee-portal/my-payment-details', data: data);
  }
}

// -----------------------------------------------------------------------------
// Time Tracking Endpoints
// -----------------------------------------------------------------------------

class TimeTrackingEndpoints extends BaseEndpoints {
  const TimeTrackingEndpoints(super.api);

  /// Clock in a worker
  Future<Response> clockIn(String workerId, {double? lat, double? lng, String? propertyId}) {
    return _api.post('/time-tracking/clock-in/$workerId', data: {
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (propertyId != null) 'propertyId': propertyId,
    });
  }

  /// Clock out a worker
  Future<Response> clockOut(
    String workerId, {
    int? breakMinutes,
    String? notes,
    double? lat,
    double? lng,
  }) {
    return _api.post('/time-tracking/clock-out/$workerId', data: {
      if (breakMinutes != null) 'breakMinutes': breakMinutes,
      if (notes != null) 'notes': notes,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    });
  }

  /// Get clock-in status for a worker
  Future<Response> getStatus(String workerId) {
    return _api.get('/time-tracking/status/$workerId');
  }

  /// Auto clock-out when worker leaves geofence
  Future<Response> autoClockOut(String workerId, {required double lat, required double lng}) {
    return _api.post('/time-tracking/auto-clock-out/$workerId', data: {
      'lat': lat,
      'lng': lng,
    });
  }

  /// Get live clock-in status of all workers
  Future<Response> getLiveStatus() {
    return _api.get('/time-tracking/live-status');
  }

  /// Get time entries for a worker
  Future<Response> getEntriesForWorker(
    String workerId, {
    required String startDate,
    required String endDate,
  }) {
    return _api.get('/time-tracking/entries/$workerId', queryParams: {
      'startDate': startDate,
      'endDate': endDate,
    });
  }

  /// Get all time entries for employer
  Future<Response> getAllEntries({
    required String startDate,
    required String endDate,
  }) {
    return _api.get('/time-tracking/entries', queryParams: {
      'startDate': startDate,
      'endDate': endDate,
    });
  }

  /// Get attendance summary
  Future<Response> getAttendanceSummary({
    required String startDate,
    required String endDate,
  }) {
    return _api.get('/time-tracking/summary', queryParams: {
      'startDate': startDate,
      'endDate': endDate,
    });
  }

  /// Adjust a time entry (employer only)
  Future<Response> adjustEntry(
    String entryId, {
    String? clockIn,
    String? clockOut,
    int? breakMinutes,
    required String reason,
  }) {
    return _api.patch('/time-tracking/entries/$entryId/adjust', data: {
      if (clockIn != null) 'clockIn': clockIn,
      if (clockOut != null) 'clockOut': clockOut,
      if (breakMinutes != null) 'breakMinutes': breakMinutes,
      'reason': reason,
    });
  }
}

// -----------------------------------------------------------------------------
// Property Endpoints
// -----------------------------------------------------------------------------

class PropertyEndpoints extends BaseEndpoints {
  const PropertyEndpoints(super.api);

  Future<Response> getAll() => _api.get('/properties');

  Future<Response> getById(String id) => _api.get('/properties/$id');

  Future<Response> create(Map<String, dynamic> data) =>
      _api.post('/properties', data: data);

  Future<Response> update(String id, Map<String, dynamic> data) =>
      _api.patch('/properties/$id', data: data);

  Future<Response> delete(String id) => _api.delete('/properties/$id');

  Future<Response> getWorkers(String id) => _api.get('/properties/$id/workers');
}

// -----------------------------------------------------------------------------
// Workers Convert Endpoints
// -----------------------------------------------------------------------------

class WorkersConvertEndpoints extends BaseEndpoints {
  const WorkersConvertEndpoints(super.api);

  Future<Response> importWorkers(PlatformFile file) async {
    // Determine content type based on file extension
    String contentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    if (file.name.endsWith('.xls')) {
      contentType = 'application/vnd.ms-excel';
    }
    
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        file.bytes!, 
        filename: file.name,
        contentType: MediaType.parse(contentType),
      ),
    });
    
    return _api.post('/excel-import/employees', data: formData);
  }

  Future<List<int>> downloadTemplate() async {
    try {
      final response = await _api.dio.get<List<int>>(
        '/excel-import/employees/template',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );
      return response.data ?? [];
    } catch (e) {
      throw _api.handleError(e);
    }

  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}