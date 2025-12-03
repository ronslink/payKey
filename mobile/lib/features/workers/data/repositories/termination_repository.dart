import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/termination_model.dart';

final terminationRepositoryProvider = Provider<TerminationRepository>((ref) {
  return TerminationRepository(const FlutterSecureStorage());
});

class TerminationRepository {
  final FlutterSecureStorage _storage;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://10.0.2.2:3000',
    headers: {'Content-Type': 'application/json'},
  ));

  TerminationRepository(this._storage);

  Future<FinalPaymentCalculation> calculateFinalPayment({
    required String workerId,
    required String terminationDate,
  }) async {
    final token = await _storage.read(key: 'access_token');
    
    final response = await _dio.post(
      '/workers/$workerId/calculate-final-payment',
      data: {'terminationDate': terminationDate},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return FinalPaymentCalculation.fromJson(response.data);
  }

  Future<Termination> terminateWorker({
    required String workerId,
    required TerminationRequest request,
  }) async {
    final token = await _storage.read(key: 'access_token');
    
    final response = await _dio.post(
      '/workers/$workerId/terminate',
      data: request.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    // Map response to include worker name
    final data = response.data as Map<String, dynamic>;
    return Termination.fromJson({
      ...data,
      'workerName': data['worker']?['name'] ?? 'Unknown',
    });
  }

  Future<List<Termination>> getTerminationHistory() async {
    final token = await _storage.read(key: 'access_token');
    
    final response = await _dio.get(
      '/workers/terminated/history',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final List<dynamic> data = response.data;
    return data.map((json) {
      final termData = json as Map<String, dynamic>;
      return Termination.fromJson({
        ...termData,
        'workerName': termData['worker']?['name'] ?? 'Unknown',
      });
    }).toList();
  }
}
