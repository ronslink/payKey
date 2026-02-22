import 'dart:math' as math;
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
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: OnboardingTheme.animationDuration,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    // Pulsing ring animation for spotlight
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _goToStep(int stepIndex) {
    _fadeController.reverse().then((_) {
      if (mounted) {
        setState(() => _currentStep = stepIndex);
        _fadeController.forward();
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

    // Spotlight rect with padding
    const padding = 12.0; // slightly more breathing room than the old 8px
    final spotlightRect = Rect.fromLTWH(
      targetPosition.dx - padding,
      targetPosition.dy - padding,
      targetSize.width + padding * 2,
      targetSize.height + padding * 2,
    );
    const spotlightRadius = OnboardingTheme.radiusLarge + 4;

    return Stack(
      children: [
        // True cutout overlay — dark background with transparent hole
        _buildCutoutOverlay(spotlightRect, spotlightRadius),
        // Animated pulsing ring around spotlight
        _buildPulsingRing(spotlightRect, spotlightRadius),
        // Tooltip card
        _buildTooltip(context, step, targetPosition, targetSize),
      ],
    );
  }

  void _handleMissingTarget() {
    // Post frame callback to avoid setState during build
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

  /// Renders the semi-transparent overlay with a rounded-rect hole cut out
  /// so the target element is fully visible through the dark scrim.
  Widget _buildCutoutOverlay(Rect spotlightRect, double radius) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {}, // block taps on overlay
        // RepaintBoundary is required for BlendMode.clear to work correctly —
        // it ensures the CustomPainter gets its own compositing layer.
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _CutoutOverlayPainter(
              spotlightRect: spotlightRect,
              spotlightRadius: radius,
              overlayColor:
                  Colors.black.withValues(alpha: OnboardingTheme.overlayOpacity),
            ),
          ),
        ),
      ),
    );
  }

  /// Animated pulsing ring that draws attention to the highlighted element
  Widget _buildPulsingRing(Rect spotlightRect, double radius) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, __) {
        final expansion = _pulseAnimation.value * 6.0;
        return Positioned(
          left: spotlightRect.left - expansion,
          top: spotlightRect.top - expansion,
          child: Container(
            width: spotlightRect.width + expansion * 2,
            height: spotlightRect.height + expansion * 2,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(radius + expansion),
              border: Border.all(
                color: OnboardingTheme.primaryBlue
                    .withValues(alpha: 0.6 - _pulseAnimation.value * 0.5),
                width: 2.5,
              ),
            ),
          ),
        );
      },
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
            targetPosition: targetPosition,
            targetSize: targetSize,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom painter: dark scrim with a transparent rounded-rect cutout
// ---------------------------------------------------------------------------

class _CutoutOverlayPainter extends CustomPainter {
  final Rect spotlightRect;
  final double spotlightRadius;
  final Color overlayColor;

  const _CutoutOverlayPainter({
    required this.spotlightRect,
    required this.spotlightRadius,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    // Fill the entire canvas
    canvas.drawRect(Offset.zero & size, paint);

    // Cut out the spotlight area by drawing transparent rounded rect
    // using BlendMode.clear — this punches a hole through the overlay
    final clearPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        spotlightRect,
        Radius.circular(spotlightRadius),
      ),
      clearPaint,
    );
  }

  @override
  bool shouldRepaint(_CutoutOverlayPainter old) =>
      old.spotlightRect != spotlightRect ||
      old.spotlightRadius != spotlightRadius ||
      old.overlayColor != overlayColor;
}

// ---------------------------------------------------------------------------
// Tooltip card
// ---------------------------------------------------------------------------

/// Tooltip content for a tour step
class _TourTooltip extends StatelessWidget {
  final TourStep step;
  final int currentIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;
  final Offset targetPosition;
  final Size targetSize;

  const _TourTooltip({
    required this.step,
    required this.currentIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
    required this.targetPosition,
    required this.targetSize,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: math.min(
        screenWidth - OnboardingTheme.tooltipMinEdgeDistance * 2,
        OnboardingTheme.maxCardWidth,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OnboardingTheme.radiusXLarge),
        boxShadow: OnboardingTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header strip with icon + title + close
          _buildGradientHeader(context),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OnboardingTheme.paddingXLarge,
              OnboardingTheme.paddingMedium,
              OnboardingTheme.paddingXLarge,
              OnboardingTheme.paddingXLarge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDescription(),
                const SizedBox(height: OnboardingTheme.paddingXLarge),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        OnboardingTheme.paddingXLarge,
        OnboardingTheme.paddingLarge,
        OnboardingTheme.paddingSmall,
        OnboardingTheme.paddingLarge,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OnboardingTheme.primaryBlue,
            OnboardingTheme.accentPurple,
          ],
        ),
      ),
      child: Row(
        children: [
          if (step.icon != null) ...[
            Container(
              padding: const EdgeInsets.all(OnboardingTheme.paddingSmall),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius:
                    BorderRadius.circular(OnboardingTheme.radiusSmall),
              ),
              child: Icon(
                step.icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: OnboardingTheme.paddingMedium),
          ],
          Expanded(
            child: Text(
              step.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Step counter e.g. "2 / 3"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${currentIndex + 1} / $totalSteps',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onSkip,
            icon: const Icon(Icons.close, size: 20),
            color: Colors.white.withValues(alpha: 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(),
            tooltip: 'Skip tour',
          ),
        ],
      ),
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
        final isPast = index < currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isCurrent ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: isCurrent
                ? OnboardingTheme.primaryBlue
                : isPast
                    ? OnboardingTheme.primaryBlue.withValues(alpha: 0.4)
                    : OnboardingTheme.borderColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButtons() {
    final isLast = currentIndex == totalSteps - 1 || step.isLast;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (currentIndex > 0) ...[
          TextButton(
            onPressed: onPrevious,
            style: TextButton.styleFrom(
              foregroundColor: OnboardingTheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Back'),
          ),
          const SizedBox(width: 4),
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
              borderRadius:
                  BorderRadius.circular(OnboardingTheme.radiusSmall),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLast ? 'Got it!' : 'Next',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (!isLast) ...[
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
