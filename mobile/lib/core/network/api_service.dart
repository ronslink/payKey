import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _initializeDio();
  }

  // Public fields for extension methods to access
  final Dio dio = Dio();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  static const String baseUrl = 'http://localhost:3000'; // Replace with actual backend URL

  void _initializeDio() {
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });
    
    // Add interceptors for auth and error handling
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to requests (but not for login/register requests)
        final isAuthEndpoint = options.uri.path.contains('/auth/login') ||
                               options.uri.path.contains('/auth/register');
        
        if (!isAuthEndpoint) {
          try {
            final token = await secureStorage.read(key: 'access_token');
            if (token != null) {
              print('🔑 Adding token to request: ${options.uri.path}');
              options.headers['Authorization'] = 'Bearer $token';
              
              // Add cache control headers to prevent 304 responses
              options.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
              options.headers['Pragma'] = 'no-cache';
              options.headers['Expires'] = '0';
            } else {
              print('⚠️ No token found for protected endpoint: ${options.uri.path}');
              print('   This will likely result in 401 Unauthorized error');
            }
          } catch (e) {
            print('❌ Error reading token from secure storage: $e');
          }
        } else {
          print('🔒 Skipping auth for auth endpoint: ${options.uri.path}');
        }
        
        // Log the complete request for debugging
        print('📤 Request: ${options.method} ${options.uri.path}');
        print('   Headers: ${options.headers}');
        if (options.data != null) {
          print('   Data: ${options.data}');
        }
        
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ Response: ${response.statusCode} ${response.requestOptions.uri.path}');
        print('   Data length: ${response.data?.length ?? 0}');
        return handler.next(response);
      },
      onError: (error, handler) async {
        // Enhanced error logging
        print('❌ API Error Details:');
        print('   Status: ${error.response?.statusCode}');
        print('   Path: ${error.requestOptions.uri.path}');
        print('   Method: ${error.requestOptions.method}');
        print('   Error Type: ${error.type}');
        print('   Error Message: ${error.message}');
        
        if (error.response?.data != null) {
          print('   Response Data: ${error.response?.data}');
        }
        
        // Handle authentication errors
        if (error.response?.statusCode == 401) {
          print('🔐 401 Unauthorized - Clearing stored token');
          await secureStorage.delete(key: 'access_token');
          // TODO: Navigate to login page
        }
        
        // Handle CORS errors specifically
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          print('🌐 Network/CORS Error - Check:');
          print('   1. Backend is running on localhost:3000');
          print('   2. CORS is enabled in backend');
          print('   3. No firewall blocking requests');
        }
        
        return handler.next(error);
      },
    ));
  }

  // Generic HTTP methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParams, Options? options}) async {
    return dio.get(path, queryParameters: queryParams, options: options);
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParams, Options? options}) async {
    return dio.post(path, data: data, queryParameters: queryParams, options: options);
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParams, Options? options}) async {
    return dio.patch(path, data: data, queryParameters: queryParams, options: options);
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParams, Options? options}) async {
    return dio.delete(path, data: data, queryParameters: queryParams, options: options);
  }

  // Auth endpoints
  Future<Response> login(String email, String password) async {
    final loginData = {
      'email': email,
      'password': password,
    };
    print('📤 Sending login request with data: $loginData');
    return dio.post('/auth/login', data: loginData);
  }

  Future<Response> register(String email, String password, {String? firstName, String? lastName}) async {
    return dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    });
  }

  // Worker endpoints
  Future<Response> getWorkers() async {
    return dio.get(
      '/workers',
      options: Options(
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0'
        }
      )
    );
  }

  Future<Response> createWorker(Map<String, dynamic> workerData) async {
    return dio.post(
      '/workers',
      data: workerData,
      options: Options(
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0'
        }
      )
    );
  }

  Future<Response> updateWorker(String workerId, Map<String, dynamic> workerData) async {
    return dio.patch(
      '/workers/$workerId',
      data: workerData,
      options: Options(
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0'
        }
      )
    );
  }

  Future<Response> deleteWorker(String workerId) async {
    return dio.delete('/workers/$workerId');
  }

  // Unified Payment Dashboard endpoints
  Future<Response> getPaymentDashboard() async {
    return dio.get('/payments/unified/dashboard');
  }

  Future<Response> getPaymentMethods() async {
    return dio.get('/payments/unified/methods');
  }

  // M-Pesa Payment endpoints
  Future<Response> initiateMpesaTopup(String phoneNumber, double amount) async {
    return dio.post('/payments/unified/mpesa/topup', data: {
      'phoneNumber': phoneNumber,
      'amount': amount,
    });
  }

  // Tax Payment endpoints
  Future<Response> getTaxPaymentSummary() async {
    return dio.get('/payments/unified/tax-payments/summary');
  }

  Future<Response> recordTaxPayment({
    required String taxType,
    required double amount,
    String? paymentDate,
    required String reference,
  }) async {
    return dio.post('/payments/unified/tax-payments/record', data: {
      'taxType': taxType,
      'amount': amount,
      'paymentDate': paymentDate,
      'reference': reference,
    });
  }

  // Legacy payment endpoints (for backward compatibility)
  Future<Response> initiateStkPush(String phoneNumber, double amount) async {
    return initiateMpesaTopup(phoneNumber, amount);
  }

  Future<Response> sendB2CPayment(String transactionId, String phoneNumber, double amount, String remarks) async {
    return dio.post('/payments/send-b2c', data: {
      'transactionId': transactionId,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'remarks': remarks,
    });
  }

  // Tax calculation methods
  Future<Response> calculateTax(double grossSalary) async {
    return dio.post('/taxes/calculate', data: {
      'grossSalary': grossSalary,
    });
  }

  // Transaction endpoints
  Future<Response> getTransactions() async {
    return dio.get('/transactions');
  }

  Future<Response> getTransactionById(String transactionId) async {
    return dio.get('/transactions/$transactionId');
  }

  // Payroll record endpoints
  Future<Response> getPayrollRecords() async {
    return dio.get('/payroll-records');
  }

  Future<Response> updatePayrollStatus(String recordId, String status, String? paymentDate) async {
    return dio.patch('/payroll-records/$recordId/status', data: {
      'status': status,
      if (paymentDate != null) 'paymentDate': paymentDate,
    });
  }

  Future<Response> deletePayrollRecord(String recordId) async {
    return dio.delete('/payroll-records/$recordId');
  }

  // Subscription endpoints
  Future<Response> getSubscriptionPlans() async {
    return dio.get(
      '/subscriptions/plans',
      options: Options(
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0'
        }
      )
    );
  }

  Future<Response> subscribeToPlan(String planId) async {
    return dio.post('/subscriptions/subscribe', data: {
      'planId': planId,
    });
  }

  Future<Response> getUserSubscription() async {
    return dio.get(
      '/subscriptions/current',
      options: Options(
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0'
        }
      )
    );
  }

  Future<Response> getSubscriptionPaymentHistory({
    int? page,
    int? limit,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (status != null) queryParams['status'] = status;
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    
    return dio.get(
      '/subscriptions/subscription-payment-history',
      queryParameters: queryParams,
      options: Options(
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0'
        }
      )
    );
  }

  Future<Response> getSubscriptionUsage() async {
    return dio.get(
      '/subscriptions/usage',
      options: Options(
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0'
        }
      )
    );
  }

  Future<Response> cancelSubscription(String subscriptionId) async {
    return dio.post('/subscriptions/$subscriptionId/cancel');
  }

  Future<Response> updateSubscription(String subscriptionId, Map<String, dynamic> updates) async {
    return dio.patch('/subscriptions/$subscriptionId', data: updates);
  }

  Future<Response> resumeSubscription(String subscriptionId) async {
    return dio.post('/subscriptions/$subscriptionId/resume');
  }

  Future<Response> upgradeSubscription(String subscriptionId, String newPlanId) async {
    return dio.post('/subscriptions/$subscriptionId/upgrade', data: {
      'newPlanId': newPlanId,
    });
  }

  // Tax endpoints
  Future<Response> getTaxSubmissions() async {
    return dio.get('/taxes/submissions');
  }

  Future<Response> markTaxAsFiled(String id) async {
    return dio.patch('/taxes/submissions/$id/file');
  }

  Future<Response> getCurrentTaxTable() async {
    return dio.get('/taxes/current');
  }

  Future<Response> getComplianceStatus() async {
    return dio.get('/taxes/compliance');
  }

  Future<Response> getTaxDeadlines() async {
    return dio.get('/taxes/deadlines');
  }

  // Tax Payments API Endpoints
  Future<Response> getMonthlyTaxSummary(int year, int month) async {
    return dio.get('/tax-payments/summary/$year/$month');
  }

  Future<Response> getTaxPaymentHistory() async {
    return dio.get('/tax-payments/history');
  }

  Future<Response> getPendingTaxPayments() async {
    return dio.get('/tax-payments/pending');
  }

  Future<Response> updateTaxPaymentStatus(String id, String status) async {
    return dio.patch('/tax-payments/$id/status', data: {'status': status});
  }

  Future<Response> getTaxPaymentInstructions() async {
    return dio.get('/tax-payments/instructions');
  }

  Future<Response> updateUserProfile(Map<String, dynamic> data) async {
    return dio.patch('/users/profile', data: data);
  }

  // Token management
  Future<void> saveToken(String token) async {
    await secureStorage.write(key: 'access_token', value: token);
  }

  Future<void> clearToken() async {
    await secureStorage.delete(key: 'access_token');
  }

  Future<String?> getToken() async {
    return await secureStorage.read(key: 'access_token');
  }

  // Error handling helper
  String getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map && data.containsKey('message')) {
          return data['message'];
        }
        return data.toString();
      }
      return error.message ?? 'Network error occurred';
    }
    return error.toString();
  }

  Exception handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        return Exception(error.response?.data['message'] ?? 'An error occurred');
      }
      return Exception(error.message);
    }
    return Exception(error.toString());
  }

  // Payroll Draft Management
  Future<Response> saveDraftPayroll(String payPeriodId, List<Map<String, dynamic>> items) async {
    return dio.post('/payroll/draft', data: {
      'payPeriodId': payPeriodId,
      'payrollItems': items,
    });
  }

  Future<Response> updatePayrollItem(String payrollRecordId, Map<String, dynamic> updates) async {
    return dio.patch('/payroll/draft/$payrollRecordId', data: updates);
  }

  Future<Response> getDraftPayroll(String payPeriodId) async {
    return dio.get('/payroll/draft/$payPeriodId');
  }

  Future<Response> finalizePayroll(String payPeriodId) async {
    return dio.post('/payroll/finalize/$payPeriodId');
  }

  Future<List<int>> downloadPayslip(String payrollRecordId) async {
    try {
      final response = await dio.get<List<int>>(
        '/payroll/payslip/$payrollRecordId',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? [];
    } catch (e) {
      throw handleError(e);
    }
  }

  // Tax Submission Management
  // Tax Submission Management
  Future<Response> generateTaxSubmission(String payPeriodId) async {
    return dio.post('/taxes/submissions/generate', data: {'payPeriodId': payPeriodId});
  }

  Future<Response> getTaxSubmissionByPeriod(String payPeriodId) async {
    return dio.get('/taxes/submissions/period/$payPeriodId');
  }

  Future<Response> getTaxSubmissions() async {
    return dio.get('/taxes/submissions');
  }

  Future<Response> markTaxSubmissionAsFiled(String id) async {
    return dio.patch('/taxes/submissions/$id/file');
  }

  Future<Response> calculateTax(double income) async {
    return dio.post('/taxes/calculate', data: {'income': income});
  }

  // Accounting Export
  Future<Response> exportPayrollToCSV(String payPeriodId) async {
    return dio.post('/accounting/export/$payPeriodId', data: {'format': 'CSV'});
  }

  Future<Response> getAccountingFormats() async {
    return dio.get('/accounting/formats');
  }

  Future<Response> getAccountMappings() async {
    return dio.get('/accounting/mappings');
  }

  Future<Response> saveAccountMappings(Map<String, dynamic> mappings) async {
    return dio.post('/accounting/mappings', data: mappings);
  }

  // Pay Period Management
  Future<Response> getPayPeriods() async {
    return dio.get('/pay-periods');
  }

  Future<Response> getPayPeriodById(String id) async {
    return dio.get('/pay-periods/$id');
  }

  Future<Response> createPayPeriod(Map<String, dynamic> data) async {
    return dio.post('/pay-periods', data: data);
  }

  Future<Response> updatePayPeriod(String id, Map<String, dynamic> data) async {
    return dio.patch('/pay-periods/$id', data: data);
  }

  Future<Response> deletePayPeriod(String id) async {
    return dio.delete('/pay-periods/$id');
  }

  Future<Response> activatePayPeriod(String id) async {
    return dio.post('/pay-periods/$id/activate');
  }

  Future<Response> processPayPeriod(String id) async {
    return dio.post('/pay-periods/$id/process');
  }

  Future<Response> completePayPeriod(String id) async {
    return dio.post('/pay-periods/$id/complete');
  }

  Future<Response> closePayPeriod(String id) async {
    return dio.post('/pay-periods/$id/close');
  }

  Future<Response> updatePayPeriodStatus(String id, String action) async {
    return dio.patch('/pay-periods/$id/status', data: {'action': action});
  }

  Future<Response> getPayPeriodStatistics(String id) async {
    return dio.get('/pay-periods/$id/statistics');
  }

  Future<Response> getCurrentPayPeriod() async {
    return dio.get('/pay-periods/current');
  }

  Future<Response> getPayPeriodsByStatus(String status) async {
    return dio.get('/pay-periods', queryParameters: {'status': status});
  }

  // Leave Management API Endpoints
  Future<Response> getLeaveRequests() async {
    return dio.get('/workers/leave-requests');
  }

  Future<Response> getWorkerLeaveRequests(String workerId) async {
    return dio.get('/workers/$workerId/leave-requests');
  }

  Future<Response> createLeaveRequest(String workerId, Map<String, dynamic> leaveData) async {
    return dio.post('/workers/$workerId/leave-requests', data: leaveData);
  }

  Future<Response> updateLeaveRequest(String leaveRequestId, Map<String, dynamic> updateData) async {
    return dio.patch('/workers/leave-requests/$leaveRequestId', data: updateData);
  }

  Future<Response> deleteLeaveRequest(String leaveRequestId) async {
    return dio.delete('/workers/leave-requests/$leaveRequestId');
  }

  Future<Response> approveLeaveRequest(String leaveRequestId, bool approved, {String? comments}) async {
    return dio.patch('/workers/leave-requests/$leaveRequestId/approve', data: {
      'approved': approved,
      if (comments != null) 'comments': comments,
    });
  }

  Future<Response> getLeaveBalance(String workerId) async {
    return dio.get('/workers/$workerId/leave-balance');
  }
}