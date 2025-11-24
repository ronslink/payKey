import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/country_model.dart';

final countriesProvider = StateNotifierProvider<CountriesNotifier, List<CountryModel>>((ref) {
  return CountriesNotifier();
});

class CountriesNotifier extends StateNotifier<List<CountryModel>> {
  CountriesNotifier() : super(_getDefaultCountries());

  static List<CountryModel> _getDefaultCountries() {
    return [
      const CountryModel(id: 'ke', name: 'Kenya', code: 'KE', phoneCode: '+254'),
      const CountryModel(id: 'ug', name: 'Uganda', code: 'UG', phoneCode: '+256'),
      const CountryModel(id: 'tz', name: 'Tanzania', code: 'TZ', phoneCode: '+255'),
      const CountryModel(id: 'rw', name: 'Rwanda', code: 'RW', phoneCode: '+250'),
      const CountryModel(id: 'et', name: 'Ethiopia', code: 'ET', phoneCode: '+251'),
    ];
  }
}