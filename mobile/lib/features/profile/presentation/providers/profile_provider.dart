import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository.dart';

/// Provider for the current user's profile
final profileProvider = FutureProvider<ProfileModel>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfile();
});

/// Convenience provider for just the user's first name
final userFirstNameProvider = Provider<String>((ref) {
  return ref.watch(profileProvider).when(
    data: (profile) => profile.firstName ?? 'there',
    loading: () => '',
    error: (_, _) => 'there',
  );
});
