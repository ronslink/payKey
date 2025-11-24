import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _initializeDio();
  }

  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String baseUrl = 'http://localhost:3000'; // Replace with actual backend URL

  void _initializeDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Add interceptors for auth and error handling
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to requests (but not for login/register requests)
        final isAuthEndpoint = options.uri.path.contains('/auth/login') ||
                               options.uri.path.contains('/auth/register');
        
        if (!isAuthEndpoint) {
          final token = await _secureStorage.read(key: 'access_token');
          if (token != null) {
            print('🔑 Adding token to request: ${options.uri.path}');
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            print('⚠️ No token found for: ${options.uri.path}');
          }
        } else {
          print('🔒 Skipping auth for auth endpoint: ${options.uri.path}');
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle different types of errors
        print('API Error: ${error.response?.statusCode} - ${error.response?.data}');
        print('Error message: ${error.message}');
        print('Error type: ${error.type}');
        
        if (error.response?.statusCode == 401) {
          await _secureStorage.delete(key: 'access_token');
          // TODO: Navigate to login page
        }
        
        // Log connection/CORS errors specifically
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          print('Connection error - likely CORS or network issue');
        }
        
        return handler.next(error);
      },
    ));
  }

  // Generic HTTP methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParams, Options? options}) async {
    return _dio.get(path, queryParameters: queryParams, options: options);
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParams, Options? options}) async {
    return _dio.post(path, data: data, queryParameters: queryParams, options: options);
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParams, Options? options}) async {
    return _dio.patch(path, data: data, queryParameters: queryParams, options: options);
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParams, Options? options}) async {
    return _dio.delete(path, data: data, queryParameters: queryParams, options: options);
  }

  // Auth endpoints
  Future<Response> login(String email, String password) async {
    final loginData = {
      'email': email,
      'password': password,
    };
    print('📤 Sending login request with data: $loginData');
    return _dio.post('/auth/login', data: loginData);
  }

  Future<Response> register(String email, String password, {String? firstName, String? lastName}) async {
    return _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    });
  }

  // Worker endpoints
  Future<Response> getWorkers() async {
    return _dio.get(
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
    return _dio.post(
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
    return _dio.patch(
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
    return _dio.delete('/workers/$workerId');
  }

  // Payment endpoints
  Future<Response> initiateStkPush(String phoneNumber, double amount) async {
    return _dio.post('/payments/initiate-stk', data: {
      'phoneNumber': phoneNumber,
      'amount': amount,
    });
  }

  Future<Response> sendB2CPayment(String transactionId, String phoneNumber, double amount, String remarks) async {
    return _dio.post('/payments/send-b2c', data: {
      'transactionId': transactionId,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'remarks': remarks,
    });
  }

  // Tax calculation methods
  Future<Response> calculateTax(double grossSalary) async {
    return _dio.post('/taxes/calculate', data: {
      'grossSalary': grossSalary,
    });
  }

  // Transaction endpoints
  Future<Response> getTransactions() async {
    return _dio.get('/transactions');
  }

  Future<Response> getTransactionById(String transactionId) async {
    return _dio.get('/transactions/$transactionId');
  }

  // Payroll record endpoints
  Future<Response> getPayrollRecords() async {
    return _dio.get('/payroll-records');
  }

  Future<Response> updatePayrollStatus(String recordId, String status, String? paymentDate) async {
    return _dio.patch('/payroll-records/$recordId/status', data: {
      'status': status,
      if (paymentDate != null) 'paymentDate': paymentDate,
    });
  }

  Future<Response> deletePayrollRecord(String recordId) async {
    return _dio.delete('/payroll-records/$recordId');
  }

  // Subscription endpoints
  Future<Response> getSubscriptionPlans() async {
    return _dio.get(
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
    return _dio.post('/subscriptions/subscribe', data: {
      'planId': planId,
    });
  }

  Future<Response> getUserSubscription() async {
    return _dio.get(
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

  // Tax endpoints
  Future<Response> getTaxSubmissions() async {
    return _dio.get('/taxes/submissions');
  }

  Future<Response> markTaxAsFiled(String id) async {
    return _dio.patch('/taxes/submissions/$id/file');
  }

  Future<Response> getCurrentTaxTable() async {
    return _dio.get('/taxes/current');
  }

  Future<Response> getComplianceStatus() async {
    return _dio.get('/taxes/compliance');
  }

  Future<Response> getTaxDeadlines() async {
    return _dio.get('/taxes/deadlines');
  }

  Future<Response> updateUserProfile(Map<String, dynamic> data) async {
    return _dio.patch('/users/profile', data: data);
  }

  // Token management
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'access_token', value: token);
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: 'access_token');
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'access_token');
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
  // Payroll Draft Management
  Future<Response> saveDraftPayroll(String payPeriodId, List<Map<String, dynamic>> items) async {
    return _dio.post('/payroll/draft', data: {
      'payPeriodId': payPeriodId,
      'payrollItems': items,
    });
  }

  Future<Response> updatePayrollItem(String payrollRecordId, Map<String, dynamic> updates) async {
    return _dio.patch('/payroll/draft/$payrollRecordId', data: updates);
  }

  Future<Response> getDraftPayroll(String payPeriodId) async {
    return _dio.get('/payroll/draft/$payPeriodId');
  }

  Future<Response> finalizePayroll(String payPeriodId) async {
    return _dio.post('/payroll/finalize/$payPeriodId');
  }
}