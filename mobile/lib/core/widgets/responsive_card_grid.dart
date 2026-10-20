import 'package:flutter/material.dart';

/// Keeps small card groups aligned without clipping wrapped or enlarged text.
class ResponsiveCardGrid extends StatelessWidget {
  const ResponsiveCardGrid({
    super.key,
    required this.children,
    this.maxColumns = 3,
    this.minColumnWidth = 100,
    this.spacing = 12,
  });

  final List<Widget> children;
  final int maxColumns;
  final double minColumnWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final columns =
            ((constraints.maxWidth + spacing) /
                    (minColumnWidth * textScale + spacing))
                .floor()
                .clamp(1, maxColumns);

        return Column(
          children: [
            for (var start = 0; start < children.length; start += columns) ...[
              if (start > 0) SizedBox(height: spacing),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      if (column > 0) SizedBox(width: spacing),
                      Expanded(
                        child: start + column < children.length
                            ? children[start + column]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
