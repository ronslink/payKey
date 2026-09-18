import 'package:dio/dio.dart';

/// Serializes registration and cleanup so token refresh/login/logout cannot race.
/// Uses a captured session for cleanup, including after local logout.
class DeviceTokenSync {
  DeviceTokenSync({required Dio client, required String platform})
    : _client = client,
      _platform = platform;

  final Dio _client;
  final String _platform;
  String? _session;
  String? _token;
  String? _registeredSession;
  String? _registeredToken;
  Future<void> _pending = Future.value();

  Future<void> updateSession(String? session) {
    _session = session;
    return retry();
  }

  Future<void> updateToken(String? token) {
    _token = token;
    return retry();
  }

  Future<void> retry() {
    final next = _pending.then((_) => _sync());
    // Keep the queue usable after a network failure. The caller handles errors.
    _pending = next.catchError((Object _) {});
    return next;
  }

  Options _authorization(String session) =>
      Options(headers: {'Authorization': 'Bearer $session'});

  Future<void> _sync() async {
    final session = _session;
    final token = _token;
    if (_registeredToken != null &&
        (_registeredToken != token || _registeredSession != session)) {
      try {
        await _client.delete(
          '/notifications/device-token/${Uri.encodeComponent(_registeredToken!)}',
          options: _authorization(_registeredSession!),
        );
      } on DioException catch (error) {
        // Expired sessions cannot perform cleanup; a fresh registration rebinds
        // the device on the server. Retry transient failures on the next event.
        if (error.response?.statusCode != 401) rethrow;
      }
      _registeredToken = null;
      _registeredSession = null;
    }
    if (session == null ||
        session.isEmpty ||
        token == null ||
        token.isEmpty ||
        (_registeredToken == token && _registeredSession == session))
      return;

    await _client.post(
      '/notifications/device-token',
      data: {'token': token, 'platform': _platform},
      options: _authorization(session),
    );
    _registeredToken = token;
    _registeredSession = session;
  }
}
