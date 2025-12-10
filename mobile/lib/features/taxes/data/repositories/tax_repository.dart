import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/payroll_tax_submission.dart';
import '../models/tax_submission_model.dart';
import '../models/monthly_tax_summary.dart';

final taxRepositoryProvider = Provider((ref) => TaxRepository());

class TaxRepository {
  final ApiService _apiService = ApiService();

  // For individual tax submissions (personal/business tax returns)
  Future<List<TaxSubmissionModel>> getIndividualTaxSubmissions() async {
    try {
      // Use the generic submissions endpoint for now, filtering if necessary
      final response = await _apiService.taxes.getSubmissions(); // Calls taxes.getSubmissions()
      if (response.data is List) {
        return (response.data as List)
            .map((json) => TaxSubmissionModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      // Fallback to empty list but log error
      return [];
    }
  }

  // For payroll tax submissions (auto-generated from payroll)
  Future<List<PayrollTaxSubmission>> getPayrollTaxSubmissions() async {
    try {
      final response = await _apiService.taxes.getSubmissions();
      final List<dynamic> data = response.data;
      return data.map((json) => PayrollTaxSubmission.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get aggregated monthly tax summaries
  Future<List<MonthlyTaxSummary>> getMonthlyTaxSummaries() async {
    try {
      final response = await _apiService.taxes.getMonthlySummaries();
      final List<dynamic> data = response.data;
      return data.map((json) => MonthlyTaxSummary.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching monthly summaries: $e');
      return [];
    }
  }

  Future<void> markMonthAsFiled(int year, int month) async {
    try {
      await _apiService.taxes.markMonthAsFiled(year, month);
    } catch (e) {
      throw Exception('Failed to file monthly taxes: $e');
    }
  }

  // Mark individual tax submission as filed
  Future<void> markIndividualTaxAsFiled(String id) async {
    try {
      await _apiService.markTaxSubmissionAsFiled(id);
    } catch (e) {
      throw Exception('Failed to mark individual tax as filed: $e');
    }
  }

  // Mark payroll tax submission as filed
  Future<void> markPayrollTaxAsFiled(String id) async {
    try {
      await _apiService.markTaxSubmissionAsFiled(id);
    } catch (e) {
      throw Exception('Failed to mark payroll tax as filed: $e');
    }
  }

  // Backward compatibility method
  Future<void> markAsFiled(String id) async {
    return markIndividualTaxAsFiled(id);
  }

  // Calculate tax for individual returns - Now uses backend API
  Future<Map<String, double>> calculateTax(double income, double deductions) async {
    try {
      // Use backend API for proper tax calculations (PAYE, NSSF, SHIF, Housing Levy)
      final apiService = ApiService();
      final response = await apiService.calculateTax(income);
      
      if (response.statusCode == 200) {
        final taxData = response.data;
        return {
          'grossIncome': income,
          'deductions': deductions,
          'taxableIncome': income - deductions, // Simplified for individual returns
          'taxAmount': taxData['paye'] ?? 0.0, // Use PAYE from backend
          'netIncome': income - (taxData['paye'] ?? 0.0),
          // Additional breakdowns from backend
          'nssf': taxData['nssf'] ?? 0.0,
          'nhif': taxData['nhif'] ?? 0.0,
          'housingLevy': taxData['housingLevy'] ?? 0.0,
          'totalDeductions': taxData['totalDeductions'] ?? 0.0,
        };
      } else {
        throw Exception('Failed to calculate tax: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to calculate tax: $e');
    }
  }
  
  // Backward compatibility alias - Now uses backend API
  Future<Map<String, double>> calculatePayrollTax(double grossSalary) async {
    try {
      // Use backend API for proper payroll tax calculations
      final apiService = ApiService();
      final response = await apiService.calculateTax(grossSalary);
      
      if (response.statusCode == 200) {
        final taxData = response.data;
        return {
          'nssf': taxData['nssf'] ?? 0.0,
          'nhif': taxData['nhif'] ?? 0.0,
          'housingLevy': taxData['housingLevy'] ?? 0.0,
          'paye': taxData['paye'] ?? 0.0,
          'totalDeductions': taxData['totalDeductions'] ?? 0.0,
          'netPay': grossSalary - (taxData['totalDeductions'] ?? 0.0),
        };
      } else {
        throw Exception('Failed to calculate payroll tax: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to calculate payroll tax: $e');
    }
  }

  // Get current tax table
  Future<Map<String, dynamic>> getCurrentTaxTable() async {
    try {
      // Return mock tax table data
      return {
        'taxYear': '2024',
        'bands': [
          {'min': 0, 'max': 288000, 'rate': 0.1},
          {'min': 288001, 'max': 388000, 'rate': 0.15},
          {'min': 388001, 'max': 6000000, 'rate': 0.3},
        ],
      };
    } catch (e) {
      throw Exception('Failed to fetch tax table: $e');
    }
  }

  // Get compliance status
  Future<Map<String, dynamic>> getComplianceStatus() async {
    try {
      final response = await _apiService.taxes.getComplianceStatus();
      if (response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
      return {
        'kraPin': false,
        'nssf': false,
        'nhif': false,
        'status': 'unknown',
      };
    } catch (e) {
      // Fallback for UI if API fails, but ideally should propagate or show error state
      debugPrint('Failed to fetch compliance status: $e');
      return {
        'kraPin': false,
        'nssf': false,
        'nhif': false,
        'status': 'error',
      };
    }
  }

  // Get tax deadlines
  Future<List<Map<String, dynamic>>> getTaxDeadlines() async {
    try {
      // Return mock tax deadlines
      return [
        {
          'title': 'Annual Tax Return',
          'description': 'Submit your annual tax return for the current year',
          'dueDate': '2024-04-30',
        },
        {
          'title': 'Quarterly PAYE',
          'description': 'Submit quarterly PAYE returns',
          'dueDate': '2024-01-15',
        },
        {
          'title': 'NSSF Returns',
          'description': 'Submit monthly NSSF contributions',
          'dueDate': '2024-01-15',
        },
      ];
    } catch (e) {
      throw Exception('Failed to fetch tax deadlines: $e');
    }
  }

  // Submit tax return
  Future<TaxSubmissionModel> submitTaxReturn(TaxSubmissionModel submission) async {
    try {
      // Mock implementation - just return the submission with updated data
      return submission.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        status: 'submitted',
      );
    } catch (e) {
      throw Exception('Failed to submit tax return: $e');
    }
  }

  Future<void> generateTaxSubmission(String payPeriodId) async {
    try {
      await _apiService.generateTaxSubmission(payPeriodId);
    } catch (e) {
      throw Exception('Failed to generate tax submission: $e');
    }
  }

  // Tax Payments API Methods
  Future<Map<String, dynamic>> getMonthlyTaxSummary(int year, int month) async {
    try {
      final response = await _apiService.getMonthlyTaxSummary(year, month);
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch monthly tax summary: $e');
    }
  }

  Future<void> recordTaxPayment(Map<String, dynamic> paymentData) async {
    try {
      await _apiService.recordTaxPayment(
        taxType: paymentData['taxType'],
        amount: paymentData['amount'],
        paymentDate: paymentData['paymentDate'],
        reference: paymentData['reference'],
      );
    } catch (e) {
      throw Exception('Failed to record tax payment: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTaxPaymentHistory() async {
    try {
      final response = await _apiService.getTaxPaymentHistory();
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Failed to fetch tax payment history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingTaxPayments() async {
    try {
      final response = await _apiService.getPendingTaxPayments();
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Failed to fetch pending tax payments: $e');
    }
  }

  Future<void> updateTaxPaymentStatus(String id, String status) async {
    try {
      await _apiService.updateTaxPaymentStatus(id, status);
    } catch (e) {
      throw Exception('Failed to update tax payment status: $e');
    }
  }

  Future<Map<String, dynamic>> getTaxPaymentInstructions() async {
    try {
      final response = await _apiService.getTaxPaymentInstructions();
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch tax payment instructions: $e');
    }
  }
  // Download statutory return (KRA, NSSF, SHIF)
  Future<String> downloadStatutoryReturn(String exportType, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _apiService.taxes.exportStatutoryReturn(
        exportType: exportType,
        startDate: startDate,
        endDate: endDate,
      );
      
      final data = response.data;
      // We expect data to contain { id, downloadUrl, fileName }
      // This ID is needed to trigger the actual download
      return data['id'] as String;
    } catch (e) {
      throw Exception('Failed to generate export: $e');
    }
  }

  Future<List<int>> getExportFile(String exportId) async {
    try {
      final response = await _apiService.taxes.downloadExport(exportId);
      // Response data should be bytes (List<int>) because responseType was bytes
      return response.data;
    } catch (e) {
      throw Exception('Failed to download export file: $e');
    }
  }
}
