import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payment_model.dart';
import '../providers/transactions_provider.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(transactionsProvider.notifier).fetchTransactions(),
          ),
        ],
      ),
      body: transactionsState.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No transactions yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _TransactionTile(transaction: transaction);
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
                onPressed: () => ref.read(transactionsProvider.notifier).fetchTransactions(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  IconData _getIcon() {
    switch (transaction.type) {
      case TransactionType.topup:
        return Icons.add_circle;
      case TransactionType.salaryPayout:
        return Icons.payments;
      case TransactionType.subscription:
        return Icons.subscriptions;
    }
  }

  Color _getStatusColor() {
    switch (transaction.status) {
      case TransactionStatus.success:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
    }
  }

  String _getTypeLabel() {
    switch (transaction.type) {
      case TransactionType.topup:
        return 'Top Up';
      case TransactionType.salaryPayout:
        return 'Salary Payout';
      case TransactionType.subscription:
        return 'Subscription';
    }
  }

  String _getStatusLabel() {
    switch (transaction.status) {
      case TransactionStatus.success:
        return 'Success';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.failed:
        return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor().withValues(alpha: 0.2),
          child: Icon(_getIcon(), color: _getStatusColor()),
        ),
        title: Text(_getTypeLabel()),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${transaction.currency} ${transaction.amount.toStringAsFixed(2)}'),
            Text(
              DateTime.parse(transaction.createdAt).toLocal().toString().split('.')[0],
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(_getStatusLabel()),
          backgroundColor: _getStatusColor().withValues(alpha: 0.2),
          labelStyle: TextStyle(color: _getStatusColor(), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
