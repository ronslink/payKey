import 'package:flutter/material.dart';
import 'accounting_page.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Finance page now shows the accounting integration
    return const AccountingPage();
  }
}
