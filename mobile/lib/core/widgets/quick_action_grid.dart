import 'package:flutter/material.dart';

/// A quick action button used in action grids.
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(
              icon,
              size: 24,
              color: iconColor ?? Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A grid of quick action buttons.
class QuickActionGrid extends StatelessWidget {
  final List<QuickActionButton> actions;
  final int crossAxisCount;
  final double spacing;

  const QuickActionGrid({
    super.key,
    required this.actions,
    this.crossAxisCount = 4,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: actions.map((action) => SizedBox(
          width: (MediaQuery.of(context).size.width - 32 - (spacing * (crossAxisCount - 1))) / crossAxisCount,
          child: action,
        )).toList(),
      ),
    );
  }
}
