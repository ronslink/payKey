import 'package:flutter/material.dart';
import '../../../core/widgets/responsive_card_grid.dart';

class FinanceQuickActions extends StatelessWidget {
  const FinanceQuickActions({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ResponsiveCardGrid(
        children: [
          _ActionCard(
            icon: Icons.receipt_long_rounded,
            title: 'Tax Records',
            subtitle: 'Statutory reports',
            gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            foreground: const Color(0xFF111827),
            onTap: () => onNavigate('/taxes'),
          ),
          _ActionCard(
            icon: Icons.description_rounded,
            title: 'Reports',
            subtitle: 'Financial reports',
            gradient: const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
            foreground: Colors.white,
            onTap: () => onNavigate('/reports'),
          ),
          _ActionCard(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Top Up',
            subtitle: 'Add funds',
            gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            foreground: const Color(0xFF111827),
            onTap: () => onNavigate('/finance/top-up'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: foreground, size: 22),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
