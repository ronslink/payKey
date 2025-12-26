import 'package:flutter/material.dart';
import '../models/tour_models.dart';
import '../theme/onboarding_theme.dart';
import '../utils/tooltip_positioner.dart';

/// Overlay that displays a guided tour with multiple steps
/// 
/// Shows a spotlight on each target element with an animated tooltip.
/// Handles step navigation, skip, and completion callbacks.
class GuidedTour extends StatefulWidget {
  /// List of tour steps to display
  final List<TourStep> steps;

  /// Called when user completes all steps
  final VoidCallback onComplete;

  /// Called when user skips the tour
  final VoidCallback onSkip;

  /// Unique key for this tour (for persistence)
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

class _GuidedTourState extends State<GuidedTour>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: OnboardingTheme.animationDuration,
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

  void _goToStep(int stepIndex) {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() => _currentStep = stepIndex);
        _animationController.forward();
      }
    });
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      _goToStep(_currentStep + 1);
    } else {
      widget.onComplete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();
    
    final step = widget.steps[_currentStep];
    final targetContext = step.targetKey.currentContext;

    // Handle missing target
    if (targetContext == null) {
      _handleMissingTarget();
      return const SizedBox.shrink();
    }

    // Ensure we have a valid render object
    final renderObject = targetContext.findRenderObject();
    if (renderObject == null || renderObject is! RenderBox) {
       _handleMissingTarget();
      return const SizedBox.shrink();
    }

    final targetPosition = renderObject.localToGlobal(Offset.zero);
    final targetSize = renderObject.size;

    return Stack(
      children: [
        _buildOverlay(),
        _buildSpotlight(targetPosition, targetSize),
        _buildTooltip(context, step, targetPosition, targetSize),
      ],
    );
  }

  void _handleMissingTarget() {
    // Post frame callback to avoid setstate during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_currentStep < widget.steps.length - 1) {
        // Skip missing step
        setState(() => _currentStep++);
      } else {
        // Or finish if it was the last one
        widget.onComplete();
      }
    });
  }

  Widget _buildOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {}, // Block taps
        child: Container(
          color: Colors.black.withValues(alpha: OnboardingTheme.overlayOpacity),
        ),
      ),
    );
  }

  Widget _buildSpotlight(Offset position, Size size) {
    return Positioned(
      left: position.dx - OnboardingTheme.spotlightPadding,
      top: position.dy - OnboardingTheme.spotlightPadding,
      child: Container(
        width: size.width + OnboardingTheme.spotlightPadding * 2,
        height: size.height + OnboardingTheme.spotlightPadding * 2,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(OnboardingTheme.radiusLarge),
          border: Border.all(
            color: OnboardingTheme.primaryBlue,
            width: OnboardingTheme.spotlightBorderWidth,
          ),
          boxShadow: OnboardingTheme.spotlightShadow,
        ),
      ),
    );
  }

  Widget _buildTooltip(
    BuildContext context,
    TourStep step,
    Offset targetPosition,
    Size targetSize,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    final positioner = TooltipPositioner(
      screenSize: screenSize,
      safeArea: safeArea,
    );

    final tooltipPos = positioner.calculate(
      targetPosition: targetPosition,
      targetSize: targetSize,
      preferredPosition: step.position,
    );

    return Positioned(
      left: tooltipPos.left,
      top: tooltipPos.top,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: _TourTooltip(
            step: step,
            currentIndex: _currentStep,
            totalSteps: widget.steps.length,
            onNext: _nextStep,
            onPrevious: _previousStep,
            onSkip: widget.onSkip,
          ),
        ),
      ),
    );
  }
}

/// Tooltip content for a tour step
class _TourTooltip extends StatelessWidget {
  final TourStep step;
  final int currentIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;

  const _TourTooltip({
    required this.step,
    required this.currentIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth - OnboardingTheme.tooltipMinEdgeDistance * 2,
      constraints: const BoxConstraints(maxWidth: OnboardingTheme.maxCardWidth),
      padding: const EdgeInsets.all(OnboardingTheme.paddingXLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OnboardingTheme.radiusXLarge),
        boxShadow: OnboardingTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: OnboardingTheme.paddingMedium),
          _buildDescription(),
          const SizedBox(height: OnboardingTheme.paddingXLarge),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (step.icon != null) ...[
          _buildIconBadge(),
          const SizedBox(width: OnboardingTheme.paddingMedium),
        ],
        Expanded(
          child: Text(step.title, style: OnboardingTextStyles.title),
        ),
        _buildCloseButton(),
      ],
    );
  }

  Widget _buildIconBadge() {
    return Container(
      padding: const EdgeInsets.all(OnboardingTheme.paddingSmall),
      decoration: BoxDecoration(
        color: OnboardingTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(OnboardingTheme.radiusSmall),
      ),
      child: Icon(
        step.icon,
        color: OnboardingTheme.primaryBlue,
        size: 20,
      ),
    );
  }

  Widget _buildCloseButton() {
    return IconButton(
      onPressed: onSkip,
      icon: const Icon(Icons.close, size: 20),
      color: OnboardingTheme.textMuted,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: 'Skip tour',
    );
  }

  Widget _buildDescription() {
    return Text(step.description, style: OnboardingTextStyles.description);
  }

  Widget _buildFooter() {
    return Row(
      children: [
        _buildProgressDots(),
        const Spacer(),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildProgressDots() {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isCurrent = index == currentIndex;
        return Container(
          width: isCurrent ? 20 : 8,
          height: 8,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: isCurrent
                ? OnboardingTheme.primaryBlue
                : OnboardingTheme.borderColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (currentIndex > 0) ...[
          TextButton(
            onPressed: onPrevious,
            child: const Text('Back'),
          ),
          const SizedBox(width: OnboardingTheme.paddingSmall),
        ],
        ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: OnboardingTheme.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: OnboardingTheme.paddingXLarge,
              vertical: OnboardingTheme.paddingMedium,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(OnboardingTheme.radiusSmall),
            ),
          ),
          child: Text(step.isLast ? 'Got it!' : 'Next'),
        ),
      ],
    );
  }
}
