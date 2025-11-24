import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/worker_model.dart';

final workersRepositoryProvider = Provider((ref) => WorkersRepository());

class WorkersRepository {
  final ApiService _apiService = ApiService();

  // Map backend JSON to Flutter WorkerModel
  WorkerModel _mapWorkerJson(Map<String, dynamic> json) {
    return WorkerModel.fromJson({
      'id': json['id'],
      'name': json['name'],
      'phoneNumber': json['phoneNumber'],
      'salaryGross': (json['salaryGross'] ?? 0.0).toDouble(),
      'startDate': json['startDate'],
      'employmentType': json['employmentType'] ?? 'FIXED',
      'hourlyRate': json['hourlyRate']?.toDouble(),
      'propertyId': json['propertyId'],
      'email': json['email'],
      'idNumber': json['idNumber'],
      'kraPin': json['kraPin'],
      'nssfNumber': json['nssfNumber'],
      'nhifNumber': json['nhifNumber'],
      'jobTitle': json['jobTitle'],
      'housingAllowance': (json['housingAllowance'] ?? 0.0).toDouble(),
      'transportAllowance': (json['transportAllowance'] ?? 0.0).toDouble(),
      'paymentFrequency': json['paymentFrequency'] ?? 'MONTHLY',
      'paymentMethod': json['paymentMethod'] ?? 'MPESA',
      'mpesaNumber': json['mpesaNumber'],
      'bankName': json['bankName'],
      'bankAccount': json['bankAccount'],
      'notes': json['notes'],
      'terminatedAt': json['terminatedAt'],
      'createdAt': json['createdAt'],
      'updatedAt': json['updatedAt'],
      'isActive': json['isActive'] ?? true,
    });
  }

  Future<List<WorkerModel>> getWorkers() async {
    try {
      final response = await _apiService.getWorkers();
      final data = response.data as List;
      
      return data.map((json) => _mapWorkerJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to fetch workers: $e');
    }
  }

  Future<WorkerModel> createWorker(CreateWorkerRequest request) async {
    try {
      final response = await _apiService.createWorker({
        'name': request.name,
        'phoneNumber': request.phoneNumber,
        'salaryGross': request.salaryGross,
        'startDate': request.startDate.toIso8601String(),
        'idNumber': request.idNumber,
        'kraPin': request.kraPin,
        'hourlyRate': request.hourlyRate,
        'propertyId': request.propertyId,
      });
      
      return _mapWorkerJson(response.data);
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to create worker: $e');
    }
  }

  Future<WorkerModel> updateWorker(String workerId, UpdateWorkerRequest request) async {
    try {
      final response = await _apiService.updateWorker(workerId, {
        if (request.name != null) 'name': request.name,
        if (request.phoneNumber != null) 'phoneNumber': request.phoneNumber,
        if (request.salaryGross != null) 'salaryGross': request.salaryGross,
        if (request.startDate != null) 'startDate': request.startDate!.toIso8601String(),
        if (request.idNumber != null) 'idNumber': request.idNumber,
        if (request.kraPin != null) 'kraPin': request.kraPin,
        if (request.hourlyRate != null) 'hourlyRate': request.hourlyRate,
        if (request.propertyId != null) 'propertyId': request.propertyId,
        if (request.isActive != null) 'isActive': request.isActive,
      });
      
      return _mapWorkerJson(response.data);
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to update worker: $e');
    }
  }

  Future<void> deleteWorker(String workerId) async {
    try {
      await _apiService.deleteWorker(workerId);
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to delete worker: $e');
    }
  }

  Future<int> getWorkerCount() async {
    try {
      final workers = await getWorkers();
      return workers.length;
    } catch (e) {
      throw Exception('Failed to get worker count: $e');
    }
  }
}
