import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/device_token_sync.dart';

class RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int nextStatus = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final status = nextStatus;
    nextStatus = 200;
    return ResponseBody.fromString(
      '{}',
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late RecordingAdapter adapter;
  late DeviceTokenSync sync;

  setUp(() {
    adapter = RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.httpClientAdapter = adapter;
    sync = DeviceTokenSync(client: dio, platform: 'ANDROID');
  });

  test(
    'waits for login, registers authenticated token, and avoids duplicates',
    () async {
      await sync.updateToken('device-token');
      expect(adapter.requests, isEmpty);
      await sync.updateSession('session-a');
      expect(adapter.requests.single.path, '/notifications/device-token');
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer session-a',
      );
      expect(adapter.requests.single.data, {
        'token': 'device-token',
        'platform': 'ANDROID',
      });
      await sync.updateToken('device-token');
      await sync.retry();
      expect(adapter.requests, hasLength(1));
    },
  );

  test(
    'refresh deactivates old token and logout uses original authorization',
    () async {
      await sync.updateSession('session-a');
      await sync.updateToken('old:token');
      await sync.updateToken('new-token');
      expect(adapter.requests[1].method, 'DELETE');
      expect(
        adapter.requests[1].path,
        '/notifications/device-token/old%3Atoken',
      );
      expect(adapter.requests[2].data['token'], 'new-token');
      await sync.updateSession(null);
      expect(adapter.requests.last.method, 'DELETE');
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer session-a',
      );
      expect(
        adapter.requests.last.path,
        '/notifications/device-token/new-token',
      );
      await sync.updateToken('later-token');
      expect(adapter.requests, hasLength(4));
    },
  );

  test(
    'account switch cleans up prior account before registering new one',
    () async {
      await sync.updateToken('shared-device');
      await sync.updateSession('session-a');
      await sync.updateSession('session-b');
      expect(adapter.requests[1].method, 'DELETE');
      expect(adapter.requests[1].headers['Authorization'], 'Bearer session-a');
      expect(adapter.requests[2].headers['Authorization'], 'Bearer session-b');
    },
  );

  test('network failure can retry without losing registration', () async {
    await sync.updateSession('session-a');
    adapter.nextStatus = 503;
    await expectLater(
      sync.updateToken('device-token'),
      throwsA(isA<DioException>()),
    );
    await sync.retry();
    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.last.data['token'], 'device-token');
  });

  test(
    'expired logout session does not prevent fresh authenticated binding',
    () async {
      await sync.updateToken('device-token');
      await sync.updateSession('expired-session');
      adapter.nextStatus = 401;
      await sync.updateSession('new-session');
      expect(adapter.requests.last.method, 'POST');
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer new-session',
      );
    },
  );
}
