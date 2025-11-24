import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/tax_submission_model.dart';

final taxRepositoryProvider = Provider((ref) => TaxRepository());

class TaxRepository {
  final ApiService _apiService = ApiService();

  Future<List<TaxSubmissionModel>> getTaxSubmissions() async {
    try {
      final response = await _apiService.getTaxSubmissions();
      return (response.data as List)
          .map((e) => TaxSubmissionModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to fetch tax submissions: $e');
    }
  }

  Future<void> markAsFiled(String id) async {
    try {
      await _apiService.markTaxAsFiled(id);
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to mark tax as filed: $e');
    }
  }

  Future<Map<String, double>> calculateTax(double grossSalary) async {
    try {
      final response = await _apiService.calculateTax(grossSalary);
      return response.data as Map<String, double>;
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to calculate tax: $e');
    }
  }

  Future<Map<String, dynamic>> getCurrentTaxTable() async {
    try {
      final response = await _apiService.getCurrentTaxTable();
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to fetch tax table: $e');
    }
  }
  Future<Map<String, dynamic>> getComplianceStatus() async {
    try {
      final response = await _apiService.getComplianceStatus();
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to fetch compliance status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTaxDeadlines() async {
    try {
      final response = await _apiService.getTaxDeadlines();
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to fetch tax deadlines: $e');
    }
  }
}
