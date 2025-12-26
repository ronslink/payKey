import 'package:flutter/material.dart';

/// Progress indicator for multi-step payroll flow
class PayrollProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String stepLabel;

  const PayrollProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              final isActive = index < currentStep;
              final isCurrent = index == currentStep - 1;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < totalSteps - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            stepLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Badge showing current tax year status
class TaxStatusBadge extends StatelessWidget {
  final int taxYear;

  const TaxStatusBadge({super.key, required this.taxYear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            '$taxYear Tax Rates Applied',
            style: TextStyle(fontSize: 12, color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no workers exist
class NoWorkersEmptyState extends StatelessWidget {
  final VoidCallback onAddWorker;

  const NoWorkersEmptyState({super.key, required this.onAddWorker});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Workers Found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add workers to run payroll',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddWorker,
            icon: const Icon(Icons.add),
            label: const Text('Add Worker'),
          ),
        ],
      ),
    );
  }
}

/// Card prompting to initialize pay periods for a year
class InitializePayPeriodsCard extends StatelessWidget {
  final int year;
  final String? subtitle;
  final VoidCallback onPressed;

  const InitializePayPeriodsCard({
    super.key,
    required this.year,
    required this.onPressed,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Initialize $year',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Initialize'),
            ),
          ],
        ),
      ),
    );
  }
}
