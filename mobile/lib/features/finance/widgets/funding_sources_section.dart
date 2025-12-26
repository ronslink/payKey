import 'package:flutter/material.dart';
import '../constants/finance_constants.dart';
import 'finance_widgets.dart';

/// Funding source display data
class FundingSourceData {
  final String? bankName;
  final String? bankAccount;
  final String? mpesaPhone;
  final String? mpesaPaybill;
  final String defaultPaymentMethod;

  const FundingSourceData({
    this.bankName,
    this.bankAccount,
    this.mpesaPhone,
    this.mpesaPaybill,

    this.defaultPaymentMethod = 'MPESA',
    this.isDirectMPesa = false,
  });

  final bool isDirectMPesa;

  bool get isBankDefault => defaultPaymentMethod == 'BANK';
  bool get isMpesaDefault => defaultPaymentMethod == 'MPESA';

  String get bankDisplayValue => bankName ?? 'Not set';
  String get mpesaDisplayValue {
    if (isDirectMPesa) return 'Direct P2P Transfer';
    return mpesaPhone ?? 'Not set';
  }
}

/// Funding sources section showing Bank and M-Pesa options
class FundingSourcesSection extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final FundingSourceData? data;
  final VoidCallback? onRetry;

  const FundingSourcesSection({
    super.key,
    required this.isLoading,
    this.error,
    this.data,
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

    final sourceData = data ?? const FundingSourceData();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FinanceTheme.pagePadding),
      child: Row(
        children: [
          Expanded(
            child: FundingSourceCard(
              icon: Icons.account_balance_outlined,
              label: 'Bank',
              value: sourceData.bankDisplayValue,
              isDefault: sourceData.isBankDefault,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FundingSourceCard(
              icon: Icons.phone_android_outlined,
              label: sourceData.isDirectMPesa ? 'Direct M-Pesa' : 'M-Pesa',
              value: sourceData.mpesaDisplayValue,
              isDefault: sourceData.isMpesaDefault,
              isDirect: sourceData.isDirectMPesa,
            ),
          ),
        ],
      ),
    );
  }
}
