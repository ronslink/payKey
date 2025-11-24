import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/country_model.dart';

final countriesProvider = FutureProvider<List<CountryModel>>((ref) async {
  final apiService = ApiService();
  final response = await apiService.get('/countries');
  
  if (response.statusCode == 200) {
    final List<dynamic> data = response.data;
    return data.map((json) => CountryModel.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load countries');
  }
});
