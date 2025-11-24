import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/termination_provider.dart';
import '../../data/models/termination_model.dart';

class ArchivedWorkersPage extends ConsumerStatefulWidget {
  const ArchivedWorkersPage({super.key});

  @override
  ConsumerState<ArchivedWorkersPage> createState() => _ArchivedWorkersPageState();
}

class _ArchivedWorkersPageState extends ConsumerState<ArchivedWorkersPage> {
  @override
  void initState() {
    super.initState();
    // FutureProvider auto-fetches, no need to manually trigger
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(terminationHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Workers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(terminationHistoryProvider);
            },
          ),
        ],
      ),
      body: historyState.when(
        data: (terminations) {
          if (terminations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.archive_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No archived workers', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: terminations.length,
            itemBuilder: (context, index) {
              final termination = terminations[index];
              return _TerminationCard(termination: termination);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(terminationHistoryProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TerminationCard extends StatelessWidget {
  final Termination termination;

  const _TerminationCard({required this.termination});

  @override
  Widget build(BuildContext context) {
    final termDate = DateTime.parse(termination.terminationDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade300,
          child: const Icon(Icons.person_off, color: Colors.grey),
        ),
        title: Text(
          termination.workerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${termination.reason.displayName} • ${termDate.day}/${termDate.month}/${termDate.year}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                _InfoRow('Termination Date', '${termDate.day}/${termDate.month}/${termDate.year}'),
                _InfoRow('Reason', termination.reason.displayName),
                if (termination.noticePeriodDays > 0)
                  _InfoRow('Notice Period', '${termination.noticePeriodDays} days'),
                const SizedBox(height: 16),
                const Text(
                  'Final Payment Breakdown',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _PaymentRow('Prorated Salary', termination.proratedSalary),
                _PaymentRow('Unused Leave Payout', termination.unusedLeavePayout),
                if (termination.severancePay > 0)
                  _PaymentRow('Severance Pay', termination.severancePay),
                const Divider(),
                _PaymentRow(
                  'Total Final Payment',
                  termination.totalFinalPayment,
                  isBold: true,
                  color: Colors.green,
                ),
                if (termination.notes != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Notes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(termination.notes!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;
  final Color? color;

  const _PaymentRow(
    this.label,
    this.amount, {
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            'KES ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
