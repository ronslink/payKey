import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageProvider = Provider((ref) {
  // Basic storage provider for now
  return const _StorageImpl();
});

class _StorageImpl {
  const _StorageImpl();
  
  // Basic implementation to prevent errors
  dynamic read(String key) => null;
  Future<void> write(String key, dynamic value) async {}
  Future<void> delete(String key) async {}
}