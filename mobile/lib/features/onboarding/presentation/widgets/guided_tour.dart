import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for tracking tour and tip progress
class TourKeys {
  static const String dashboardTour = 'tour_dashboard';
  static const String payrollTour = 'tour_payroll';
  static const String workersTour = 'tour_workers';
  static const String reportsTour = 'tour_reports';
  
  static const String tipFirstWorker = 'tip_first_worker';
  static const String tipFirstPayroll = 'tip_first_payroll';
  static const String tipLeaveManagement = 'tip_leave_management';
  static const String tipTimeTracking = 'tip_time_tracking';
  static const String tipReports = 'tip_reports';
}

/// Provider for tour progress state
final tourProgressProvider = StateNotifierProvider<TourProgressNotifier, TourProgress>((ref) {
  return TourProgressNotifier();
});

/// Model for tracking tour and tip completion status
class TourProgress {
  final Set<String> completedTours;
  final Set<String> dismissedTips;
  final DateTime? lastTourShown;
  final bool isLoaded;

  const TourProgress({
    this.completedTours = const {},
    this.dismissedTips = const {},
    this.lastTourShown,
    this.isLoaded = false,
  });

  TourProgress copyWith({
    Set<String>? completedTours,
    Set<String>? dismissedTips,
    DateTime? lastTourShown,
    bool? isLoaded,
  }) {
    return TourProgress(
      completedTours: completedTours ?? this.completedTours,
      dismissedTips: dismissedTips ?? this.dismissedTips,
      lastTourShown: lastTourShown ?? this.lastTourShown,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  bool hasSeen(String key) => completedTours.contains(key) || dismissedTips.contains(key);

  /// Returns true if we can show a tour (max one per session)
  bool get canShowTour {
    if (lastTourShown == null) return true;
    return DateTime.now().difference(lastTourShown!).inHours >= 1;
  }
}

/// Notifier for managing tour progress
class TourProgressNotifier extends StateNotifier<TourProgress> {
  TourProgressNotifier() : super(const TourProgress()) {
    _loadProgress();
  }

  static const String _completedToursKey = 'completed_tours';
  static const String _dismissedTipsKey = 'dismissed_tips';

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final completedTours = prefs.getStringList(_completedToursKey)?.toSet() ?? {};
    final dismissedTips = prefs.getStringList(_dismissedTipsKey)?.toSet() ?? {};
    
    state = state.copyWith(
      completedTours: completedTours,
      dismissedTips: dismissedTips,
      isLoaded: true,
    );
  }

  Future<void> completeTour(String tourKey) async {
    final newTours = {...state.completedTours, tourKey};
    state = state.copyWith(
      completedTours: newTours,
      lastTourShown: DateTime.now(),
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_completedToursKey, newTours.toList());
  }

  Future<void> dismissTip(String tipKey) async {
    final newTips = {...state.dismissedTips, tipKey};
    state = state.copyWith(dismissedTips: newTips);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_dismissedTipsKey, newTips.toList());
  }

  Future<void> resetAll() async {
    state = const TourProgress(isLoaded: true);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedToursKey);
    await prefs.remove(_dismissedTipsKey);
  }
}

/// A single step in a guided tour
class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final TourStepPosition position;
  final bool isLast;
  final IconData? icon;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.position = TourStepPosition.below,
    this.isLast = false,
    this.icon,
  });
}

/// Position of the tour tooltip relative to the target
enum TourStepPosition {
  above,
  below,
  left,
  right,
}

/// Overlay that displays a guided tour with multiple steps
class GuidedTour extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final String tourKey;

  const GuidedTour({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.onSkip,
    required this.tourKey,
  });

  @override
  State<GuidedTour> createState() => _GuidedTourState();
}

class _GuidedTourState extends State<GuidedTour> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      _animationController.reverse().then((_) {
        setState(() => _currentStep++);
        _animationController.forward();
      });
    } else {
      widget.onComplete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _animationController.reverse().then((_) {
        setState(() => _currentStep--);
        _animationController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final targetContext = step.targetKey.currentContext;
    
    if (targetContext == null) {
      // Target not found, skip to next or complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentStep < widget.steps.length - 1) {
          setState(() => _currentStep++);
        } else {
          widget.onComplete();
        }
      });
      return const SizedBox.shrink();
    }

    final RenderBox renderBox = targetContext.findRenderObject() as RenderBox;
    final targetPosition = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;

    return Stack(
      children: [
        // Semi-transparent overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () {}, // Prevent taps from going through
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
        ),

        // Spotlight on target
        Positioned(
          left: targetPosition.dx - 8,
          top: targetPosition.dy - 8,
          child: Container(
            width: targetSize.width + 16,
            height: targetSize.height + 16,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF3B82F6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
        ),

        // Tour tooltip
        Positioned(
          left: _getTooltipLeft(step.position, targetPosition, targetSize),
          top: _getTooltipTop(step.position, targetPosition, targetSize),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: MediaQuery.of(context).size.width - 48,
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon
                    Row(
                      children: [
                        if (step.icon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              step.icon,
                              color: const Color(0xFF3B82F6),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onSkip,
                          icon: const Icon(Icons.close, size: 20),
                          color: const Color(0xFF9CA3AF),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      step.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Progress and navigation
                    Row(
                      children: [
                        // Progress dots
                        Row(
                          children: List.generate(widget.steps.length, (index) {
                            return Container(
                              width: index == _currentStep ? 20 : 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: index == _currentStep
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                        const Spacer(),

                        // Navigation buttons
                        if (_currentStep > 0)
                          TextButton(
                            onPressed: _previousStep,
                            child: const Text('Back'),
                          ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(step.isLast ? 'Got it!' : 'Next'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _getTooltipLeft(TourStepPosition position, Offset target, Size targetSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    switch (position) {
      case TourStepPosition.left:
        return 24;
      case TourStepPosition.right:
        return screenWidth - 340 - 24;
      default:
        return 24;
    }
  }

  double _getTooltipTop(TourStepPosition position, Offset target, Size targetSize) {
    switch (position) {
      case TourStepPosition.above:
        return target.dy - 200;
      case TourStepPosition.below:
        return target.dy + targetSize.height + 16;
      case TourStepPosition.left:
      case TourStepPosition.right:
        return target.dy;
    }
  }
}

/// A single contextual tip that appears when a user first visits a feature
class FeatureTip extends StatelessWidget {
  final String tipKey;
  final String title;
  final String description;
  final IconData icon;
  final Widget child;
  final VoidCallback? onActionPressed;
  final String? actionText;

  const FeatureTip({
    super.key,
    required this.tipKey,
    required this.title,
    required this.description,
    required this.icon,
    required this.child,
    this.onActionPressed,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final progress = ref.watch(tourProgressProvider);
        
        // Don't show if not loaded yet or already dismissed
        if (!progress.isLoaded || progress.hasSeen(tipKey)) {
          return child;
        }

        return Stack(
          children: [
            child,
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _TipCard(
                      title: title,
                      description: description,
                      icon: icon,
                      onDismiss: () {
                        ref.read(tourProgressProvider.notifier).dismissTip(tipKey);
                      },
                      onAction: onActionPressed,
                      actionText: actionText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onDismiss;
  final VoidCallback? onAction;
  final String? actionText;

  const _TipCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onDismiss,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
              ),
              if (onAction != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onDismiss();
                      onAction!();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(actionText ?? 'Continue'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Welcome message shown to new users
class WelcomeBanner extends StatelessWidget {
  final String userName;
  final VoidCallback onDismiss;
  final VoidCallback onStartTour;

  const WelcomeBanner({
    super.key,
    required this.userName,
    required this.onDismiss,
    required this.onStartTour,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $userName! 👋',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Let\'s get you started with PayKey. We\'ll show you around!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onStartTour,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Start Tour'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
                child: const Text('Maybe later'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
