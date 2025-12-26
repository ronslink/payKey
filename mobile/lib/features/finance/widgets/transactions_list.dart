import 'package:flutter/material.dart';
import '../constants/finance_constants.dart';
import 'finance_widgets.dart';

/// Model for a transaction display item
class TransactionDisplayItem {
  final String id;
  final String name;
  final DateTime date;
  final double amount;
  final bool isCompleted;

  const TransactionDisplayItem({
    required this.id,
    required this.name,
    required this.date,
    required this.amount,
    this.isCompleted = true,
  });
}

/// List of recent transactions/payroll runs
class TransactionsList extends StatelessWidget {
  final List<TransactionDisplayItem> transactions;
  final VoidCallback onRunPayroll;
  final int maxItems;

  const TransactionsList({
    super.key,
    required this.transactions,
    required this.onRunPayroll,
    this.maxItems = FinanceConstants.maxRecentTransactions,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return EmptyTransactionsState(onRunPayroll: onRunPayroll);
    }

    final displayItems = transactions.take(maxItems).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: FinanceTheme.pagePadding),
      decoration: FinanceTheme.cardDecoration(),
      child: Column(
        children: displayItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == displayItems.length - 1;

          return TransactionListItem(
            title: item.name,
            date: item.date,
            amount: item.amount,
            showDivider: !isLast,
          );
        }).toList(),
      ),
    );
  }
}

/// Transactions section with loading/error states
class TransactionsSection extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<TransactionDisplayItem> transactions;
  final VoidCallback onRunPayroll;
  final VoidCallback? onRetry;

  const TransactionsSection({
    super.key,
    required this.isLoading,
    this.error,
    required this.transactions,
    required this.onRunPayroll,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const FinanceLoadingState();
    }

    if (error != null) {
      return FinanceErrorState(
        message: error!,
        onRetry: onRetry,
      );
    }

    return TransactionsList(
      transactions: transactions,
      onRunPayroll: onRunPayroll,
    );
  }
}
