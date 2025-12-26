import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/payroll_confirm_constants.dart';
import '../models/payroll_confirm_state.dart';

/// Payment results page shown after processing
class PaymentResultsPage extends StatelessWidget {
  final PayrollBatchResult result;
  final VoidCallback onBackToHome;

  const PaymentResultsPage({
    super.key,
    required this.result,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Payment Results'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildStatusHeader(),
          const Divider(),
          Expanded(child: _buildWorkerList()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          _buildStatusIcon(),
          const SizedBox(height: 16),
          Text(
            result.allSuccess
                ? 'All Payments Initiated'
                : 'Payments Completed with Errors',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            result.allSuccess
                ? 'Workers will receive M-Pesa notifications shortly.'
                : '${result.successCount} successful, ${result.failureCount} failed.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    final isSuccess = result.allSuccess;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.orange.shade50,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isSuccess ? Icons.check_rounded : Icons.priority_high_rounded,
        size: 48,
        color: isSuccess
            ? PayrollConfirmTheme.successGreen
            : PayrollConfirmTheme.warningOrange,
      ),
    );
  }

  Widget _buildWorkerList() {
    return ListView.separated(
      itemCount: result.results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = result.results[index];
        return WorkerResultTile(result: item);
      },
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onBackToHome,
          style: PayrollConfirmTheme.darkButtonStyle,
          child: const Text('Back to Home'),
        ),
      ),
    );
  }
}

/// Individual worker result tile
class WorkerResultTile extends StatelessWidget {
  final PayrollWorkerResult result;

  const WorkerResultTile({
    super.key,
    required this.result,
  });

  static final _currencyFormat = NumberFormat('#,##0');

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildLeadingIcon(),
      title: Text(
        result.workerName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: _buildSubtitle(),
      trailing: result.success
          ? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
          : null,
    );
  }

  Widget _buildLeadingIcon() {
    return CircleAvatar(
      backgroundColor: result.success
          ? Colors.green.shade100
          : Colors.red.shade100,
      child: Icon(
        result.success ? Icons.check : Icons.close,
        color: result.success
            ? PayrollConfirmTheme.successGreen
            : PayrollConfirmTheme.errorRed,
        size: 20,
      ),
    );
  }

  Widget _buildSubtitle() {
    if (result.success) {
      return Text(
        'Net Pay: ${PayrollConfirmConstants.currencyCode} ${_currencyFormat.format(result.netPay)}',
      );
    }

    return Text(
      result.error ?? 'Unknown error',
      style: const TextStyle(
        color: PayrollConfirmTheme.errorRed,
        fontSize: 13,
      ),
    );
  }
}
