import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/holiday_model.dart';

final holidaysRepositoryProvider = Provider<HolidaysRepository>((ref) {
  return HolidaysRepository(ref.watch(apiClientProvider));
});

class HolidaysRepository {
  final Dio _client;

  HolidaysRepository(this._client);

  Future<List<HolidayModel>> getHolidays() async {
    try {
      final response = await _client.get('/holidays');
      return (response.data as List)
          .map((e) => HolidayModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch holidays: $e');
    }
  }
}
