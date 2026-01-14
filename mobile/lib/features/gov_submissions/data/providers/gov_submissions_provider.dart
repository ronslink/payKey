import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/gov_submission_model.dart';

/// Provider to fetch all government submissions
final govSubmissionsProvider = FutureProvider.autoDispose<List<GovSubmission>>((ref) async {
  final response = await ApiService().gov.getSubmissions();
  final List<dynamic> data = response.data as List<dynamic>;
  return data.map((json) => GovSubmission.fromJson(json as Map<String, dynamic>)).toList();
});

/// Provider to generate a KRA P10 file
final generateKraP10Provider = FutureProvider.autoDispose.family<GovSubmission, String>((ref, payPeriodId) async {
  final response = await ApiService().gov.generateKraP10(payPeriodId);
  return GovSubmission.fromJson(response.data as Map<String, dynamic>);
});

/// Provider to generate a SHIF file
final generateShifProvider = FutureProvider.autoDispose.family<GovSubmission, String>((ref, payPeriodId) async {
  final response = await ApiService().gov.generateShif(payPeriodId);
  return GovSubmission.fromJson(response.data as Map<String, dynamic>);
});

/// Provider to generate a NSSF file
final generateNssfProvider = FutureProvider.autoDispose.family<GovSubmission, String>((ref, payPeriodId) async {
  final response = await ApiService().gov.generateNssf(payPeriodId);
  return GovSubmission.fromJson(response.data as Map<String, dynamic>);
});
