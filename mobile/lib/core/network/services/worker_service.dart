import 'package:dio/dio.dart';
import '../api_service.dart';

extension WorkerService on ApiService {
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
}
