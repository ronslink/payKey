import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/property_form_constants.dart';

/// Gradient background with decorative orbs
class PropertyFormBackground extends StatelessWidget {
  final Widget child;

  const PropertyFormBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: PropertyFormTheme.backgroundGradient,
              ),
            ),
          ),
        ),

        // Top-right decorative orb
        Positioned(
          top: -100,
          right: -100,
          child: _DecorativeOrb(
            size: PropertyFormTheme.topOrbSize,
            color: PropertyFormTheme.blueOrbColor,
          ),
        ),

        // Bottom-left decorative orb
        Positioned(
          bottom: -50,
          left: -50,
          child: _DecorativeOrb(
            size: PropertyFormTheme.bottomOrbSize,
            color: PropertyFormTheme.greenOrbColor,
          ),
        ),

        // Content
        child,
      ],
    );
  }
}

class _DecorativeOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorativeOrb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: PropertyFormConstants.decorativeBlurSigma,
        sigmaY: PropertyFormConstants.decorativeBlurSigma,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

/// Header with back button and title
class PropertyFormHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const PropertyFormHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 16),
      child: Row(
        children: [
          _buildBackButton(context),
          const SizedBox(width: 8),
          Expanded(child: _buildTitleSection()),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(PropertyFormTheme.headerIconRadius),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
      ),
      onPressed: onBack,
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

/// Glassmorphism card container
class GlassCard extends StatelessWidget {
  final Widget child;
  final Animation<double>? animation;

  const GlassCard({
    super.key,
    required this.child,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(PropertyFormTheme.cardBorderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: PropertyFormConstants.glassBlurSigma,
          sigmaY: PropertyFormConstants.glassBlurSigma,
        ),
        child: Container(
          padding: const EdgeInsets.all(PropertyFormTheme.cardPadding),
          decoration: BoxDecoration(
            color: PropertyFormTheme.glassBackground,
            borderRadius: BorderRadius.circular(PropertyFormTheme.cardBorderRadius),
            border: Border.all(
              color: PropertyFormTheme.glassBorder,
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (animation != null) {
      return FadeTransition(
        opacity: animation!,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation!,
            curve: Curves.easeOutQuart,
          )),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Section header with icon
class FormSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const FormSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildIconContainer(),
        const SizedBox(width: 16),
        Expanded(child: _buildTextColumn()),
      ],
    );
  }

  Widget _buildIconContainer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: PropertyFormTheme.iconGradient),
        borderRadius: BorderRadius.circular(PropertyFormTheme.sectionIconRadius),
      ),
      child: Icon(
        icon,
        color: PropertyFormTheme.lightBlue,
        size: 24,
      ),
    );
  }

  Widget _buildTextColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}

/// Styled text field for property form
class PropertyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? helperText;
  final String? Function(String?)? validator;

  const PropertyTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
    this.helperText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        const SizedBox(height: 8),
        _buildTextField(),
      ],
    );
  }

  Widget _buildLabel() {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(color: PropertyFormTheme.errorRed),
          ),
      ],
    );
  }

  Widget _buildTextField() {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: PropertyFormTheme.fieldDecoration(
        hint: hint,
        icon: icon,
        helperText: helperText,
      ),
      validator: validator ?? _defaultValidator,
    );
  }

  String? _defaultValidator(String? value) {
    if (required && (value == null || value.trim().isEmpty)) {
      return 'This field is required';
    }
    return null;
  }
}

/// Submit button with loading state
class PropertySubmitButton extends StatelessWidget {
  final bool isLoading;
  final bool isEditing;
  final VoidCallback? onPressed;

  const PropertySubmitButton({
    super.key,
    required this.isLoading,
    required this.isEditing,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PropertyFormTheme.cardPadding),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: PropertyFormTheme.primaryButtonStyle,
          child: isLoading ? _buildLoadingIndicator() : _buildButtonContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildButtonContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(isEditing ? Icons.save : Icons.add_home_work),
        const SizedBox(width: 12),
        Text(
          isEditing ? 'Update Property' : 'Create Property',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
