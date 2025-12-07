import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transactions_repository.dart';

class PaymentDetailPage extends ConsumerStatefulWidget {
  final String transactionId;
  final TransactionModel? transaction; // Optional - for passing from list

  const PaymentDetailPage({
    super.key,
    required this.transactionId,
    this.transaction,
  });

  @override
  ConsumerState<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends ConsumerState<PaymentDetailPage> {
  TransactionModel? _transaction;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use passed transaction if available, otherwise fetch from API
    if (widget.transaction != null) {
      setState(() {
        _transaction = widget.transaction;
        _isLoading = false;
      });
    } else {
      _loadTransactionDetails();
    }
  }

  Future<void> _loadTransactionDetails() async {
    try {
      final repository = ref.read(transactionsRepositoryProvider);
      final transaction = await repository.getTransactionById(widget.transactionId);
      setState(() {
        _transaction = transaction;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load transaction details: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        title: const Text(
          'Payment Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B7280)),
          onPressed: () => context.go('/payments'),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _transaction == null
              ? const Center(
                  child: Text('Transaction not found'),
                )
              : _buildTransactionDetails(_transaction!),
    );
  }

  Widget _buildTransactionDetails(TransactionModel transaction) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(transaction),
          const SizedBox(height: 20),
          _buildPaymentInfoCard(transaction),
          const SizedBox(height: 20),
          _buildTransactionDetailsCard(transaction),
          const SizedBox(height: 20),
          _buildStatusCard(transaction),
          if (transaction.invoiceUrl != null) ...[
            const SizedBox(height: 20),
            _buildInvoiceCard(transaction),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCard(TransactionModel transaction) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black .withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getPaymentMethodColor(transaction.paymentMethod),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  _getPaymentMethodIcon(transaction.paymentMethod),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${transaction.currency} ${transaction.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPaymentMethodName(transaction.paymentMethod),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(transaction.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  transaction.status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard(TransactionModel transaction) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black .withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Payment Method', _getPaymentMethodName(transaction.paymentMethod), Icons.payment),
          if (transaction.stripePaymentIntentId != null)
            _buildDetailRow('Stripe Payment ID', transaction.stripePaymentIntentId!, Icons.credit_card),
          if (transaction.mpesaTransactionId != null)
            _buildDetailRow('M-Pesa Transaction ID', transaction.mpesaTransactionId!, Icons.phone_android),
        ],
      ),
    );
  }

  Widget _buildTransactionDetailsCard(TransactionModel transaction) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black .withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Transaction ID', transaction.id, Icons.receipt),
          _buildDetailRow('Created', _formatDate(transaction.createdAt), Icons.calendar_today),
          if (transaction.succeededAt != null)
            _buildDetailRow('Completed', _formatDate(transaction.succeededAt!), Icons.check_circle),
          _buildDetailRow('Currency', transaction.currency, Icons.attach_money),
          _buildDetailRow('Amount', '${transaction.currency} ${transaction.amount.toStringAsFixed(2)}', Icons.payments),
        ],
      ),
    );
  }

  Widget _buildStatusCard(TransactionModel transaction) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black .withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(transaction.status) .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(transaction.status) .withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(transaction.status),
                  color: _getStatusColor(transaction.status),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusMessage(transaction.status),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(transaction.status),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(TransactionModel transaction) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black .withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invoice',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Open invoice URL
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invoice functionality coming soon'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.download),
              label: const Text('Download Invoice'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'stripe':
        return const Color(0xFF635BFF);
      case 'mpesa':
        return const Color(0xFF00D632);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'stripe':
        return Icons.credit_card;
      case 'mpesa':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentMethodName(String method) {
    switch (method.toLowerCase()) {
      case 'stripe':
        return 'Credit/Debit Card';
      case 'mpesa':
        return 'M-Pesa';
      default:
        return method;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'failed':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return 'Payment Successful';
      case 'pending':
        return 'Payment Pending';
      case 'failed':
        return 'Payment Failed';
      default:
        return 'Unknown Status';
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return 'Your payment has been processed successfully';
      case 'pending':
        return 'Your payment is being processed';
      case 'failed':
        return 'There was an issue processing your payment';
      default:
        return 'Payment status is unknown';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}