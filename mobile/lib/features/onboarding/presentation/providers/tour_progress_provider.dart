import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tour_models.dart';

/// Storage keys for SharedPreferences
class _StorageKeys {
  static const String completedTours = 'onboarding_completed_tours';
  static const String dismissedTips = 'onboarding_dismissed_tips';
}

/// Notifier for managing tour progress state
/// 
/// Handles persistence via SharedPreferences with proper error handling.
class TourProgressNotifier extends Notifier<TourProgress> {
  @override
  TourProgress build() {
    // Start loading immediately but don't block
    _initializeAsync();
    return const TourProgress.loading();
  }

  /// Initialize state from SharedPreferences
  Future<void> _initializeAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final completedTours =
          prefs.getStringList(_StorageKeys.completedTours)?.toSet() ?? {};
      final dismissedTips =
          prefs.getStringList(_StorageKeys.dismissedTips)?.toSet() ?? {};

      state = TourProgress(
        completedTours: completedTours,
        dismissedTips: dismissedTips,
        isLoaded: true,
      );
    } catch (e) {
      // Log error in production
      state = TourProgress.withError('Failed to load tour progress: $e');
    }
  }

  /// Mark a tour as completed
  Future<bool> completeTour(String tourKey) async {
    try {
      final newTours = {...state.completedTours, tourKey};
      
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setStringList(
        _StorageKeys.completedTours,
        newTours.toList(),
      );

      if (success) {
        state = state.copyWith(
          completedTours: newTours,
          lastTourShown: DateTime.now(),
        );
      }
      
      return success;
    } catch (e) {
      // Fail silently but return false
      return false;
    }
  }

  /// Dismiss a tip
  Future<bool> dismissTip(String tipKey) async {
    try {
      final newTips = {...state.dismissedTips, tipKey};
      
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setStringList(
        _StorageKeys.dismissedTips,
        newTips.toList(),
      );

      if (success) {
        state = state.copyWith(dismissedTips: newTips);
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Reset all tour and tip progress (for testing or settings)
  Future<bool> resetAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await Future.wait([
        prefs.remove(_StorageKeys.completedTours),
        prefs.remove(_StorageKeys.dismissedTips),
      ]);

      state = const TourProgress(isLoaded: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reset only tours (keep tips dismissed)
  Future<bool> resetTours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_StorageKeys.completedTours);

      state = state.copyWith(
        completedTours: {},
        lastTourShown: null,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if user should see onboarding (new user detection)
  bool get isNewUser =>
      state.isLoaded &&
      state.completedTours.isEmpty &&
      state.dismissedTips.isEmpty;
}

/// Provider for tour progress state
final tourProgressProvider =
    NotifierProvider<TourProgressNotifier, TourProgress>(
  TourProgressNotifier.new,
);

/// Convenience provider to check if a specific tour/tip has been seen
final hasSeenProvider = Provider.family<bool, String>((ref, key) {
  final progress = ref.watch(tourProgressProvider);
  return progress.hasSeen(key);
});

/// Convenience provider to check if tours can be shown
final canShowTourProvider = Provider<bool>((ref) {
  final progress = ref.watch(tourProgressProvider);
  return progress.isLoaded && progress.canShowTour;
});
