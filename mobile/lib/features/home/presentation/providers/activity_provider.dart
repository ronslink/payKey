import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_service.dart';
import '../data/models/activity_model.dart';

final recentActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final apiService = ApiService();
  final response = await apiService.getRecentActivities();
  
  if (response.data != null && response.data['activities'] != null) {
    return (response.data['activities'] as List)
        .map((json) => Activity.fromJson(json))
        .toList();
  }
  
  return [];
});
