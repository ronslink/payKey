import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../models/support_ticket.dart';
import '../../models/support_message.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(
    dio: ref.read(apiClientProvider),
    storage: const FlutterSecureStorage(),
  );
});

class SupportRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  SupportRepository({required Dio dio, required FlutterSecureStorage storage})
      : _dio = dio,
        _storage = storage;

  Future<String?> _getToken() => _storage.read(key: 'access_token');

  Future<List<SupportTicket>> getTickets() async {
    final token = await _getToken();
    final response = await _dio.get(
      '/support/tickets',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final data = response.data as List;
    return data.map((item) => SupportTicket.fromJson(item)).toList();
  }

  Future<SupportTicket> getTicket(String id) async {
    final token = await _getToken();
    final response = await _dio.get(
      '/support/tickets/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return SupportTicket.fromJson(response.data);
  }

  Future<SupportTicket> createTicket(String subject, String description, TicketCategory category) async {
    final token = await _getToken();
    final response = await _dio.post(
      '/support/tickets',
      data: {
        'subject': subject,
        'description': description,
        'category': category.name,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return SupportTicket.fromJson(response.data);
  }

  Future<SupportMessage> addReply(String ticketId, String message) async {
    final token = await _getToken();
    final response = await _dio.post(
      '/support/tickets/$ticketId/messages',
      data: {'message': message},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return SupportMessage.fromJson(response.data);
  }
}
