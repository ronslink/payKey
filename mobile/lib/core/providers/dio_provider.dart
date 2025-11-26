import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Dio provider for HTTP client
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  // Configure dio here if needed
  return dio;
});