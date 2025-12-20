import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/country_model.dart';
import '../../../../../core/network/api_service.dart';

final countriesProvider = StateNotifierProvider<CountriesNotifier, List<CountryModel>>((ref) {
  return CountriesNotifier()..loadCountries();
});

class CountriesNotifier extends StateNotifier<List<CountryModel>> {
  CountriesNotifier() : super([]);

  Future<void> loadCountries() async {
    try {
      final apiService = ApiService();
      final response = await apiService.getCountries();
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        state = data.map((json) => CountryModel.fromJson(json)).toList();
      }
    } catch (e) {
      // Fallback to default countries if API fails
      state = _getDefaultCountries();
    }
  }

  static List<CountryModel> _getDefaultCountries() {
    return [
      const CountryModel(id: 'ke', name: 'Kenya', code: 'KE', currency: 'KES'),
      const CountryModel(id: 'ug', name: 'Uganda', code: 'UG', currency: 'UGX'),
      const CountryModel(id: 'tz', name: 'Tanzania', code: 'TZ', currency: 'TZS'),
      const CountryModel(id: 'rw', name: 'Rwanda', code: 'RW', currency: 'RWF'),
      const CountryModel(id: 'et', name: 'Ethiopia', code: 'ET', currency: 'ETB'),
    ];
  }
}