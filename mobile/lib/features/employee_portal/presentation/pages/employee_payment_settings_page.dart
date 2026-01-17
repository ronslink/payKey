import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../workers/presentation/providers/workers_provider.dart';

class EmployeePaymentSettingsPage extends ConsumerStatefulWidget {
  const EmployeePaymentSettingsPage({super.key});

  @override
  ConsumerState<EmployeePaymentSettingsPage> createState() => _EmployeePaymentSettingsPageState();
}

class _EmployeePaymentSettingsPageState extends ConsumerState<EmployeePaymentSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form Fields
  String _paymentMethod = 'MPESA'; // Default
  String? _bankCode; // For dropdown value
  final _bankNameController = TextEditingController(); // For saving name
  final _bankAccountController = TextEditingController();
  final _mpesaPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _mpesaPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().employeePortal.getMyProfile();
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _paymentMethod = data['paymentMethod'] ?? 'MPESA';
          _bankCode = data['bankCode']; // Ideally returned from backend
          _bankNameController.text = data['bankName'] ?? '';
          _bankAccountController.text = data['bankAccount'] ?? '';
          _mpesaPhoneController.text = data['mpesaNumber'] ?? '';
          
          if (_bankCode != null && _bankNameController.text.isEmpty) {
             // If we have code but no name, we might fetch name from provider later, 
             // but usually backend returns both.
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final payload = {
        'paymentMethod': _paymentMethod,
        if (_paymentMethod == 'BANK') ...{
          'bankName': _bankNameController.text,
          'bankCode': _bankCode,
          'bankAccount': _bankAccountController.text,
        },
        if (_paymentMethod == 'MPESA') ...{
          'mpesaNumber': _mpesaPhoneController.text,
        }
      };

      await ApiService().employeePortal.updatePaymentDetails(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment details updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Preferred Payment Method'),
                    const SizedBox(height: 16),
                    _buildPaymentMethodSelector(),
                    const SizedBox(height: 24),
                    if (_paymentMethod == 'BANK') _buildBankFields(),
                    if (_paymentMethod == 'MPESA') _buildMpesaFields(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _isLoading ? 'Saving...' : 'Save Changes',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          RadioListTile<String>(
            title: const Text('M-Pesa'),
            subtitle: const Text('Receive payments via mobile money'),
            value: 'MPESA',
            // ignore: deprecated_member_use
            groupValue: _paymentMethod,
            // ignore: deprecated_member_use
            onChanged: (val) => setState(() => _paymentMethod = val ?? 'MPESA'),
            secondary: const Icon(Icons.phone_android),
          ),
          const Divider(height: 1),
          RadioListTile<String>(
            title: const Text('Bank Transfer'),
            subtitle: const Text('Direct deposit to your bank account'),
            value: 'BANK',
            // ignore: deprecated_member_use
            groupValue: _paymentMethod,
            // ignore: deprecated_member_use
            onChanged: (val) => setState(() => _paymentMethod = val ?? 'MPESA'),
            secondary: const Icon(Icons.account_balance),
          ),
        ],
      ),
    );
  }

  Widget _buildBankFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Bank Details'),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            final banksAsync = ref.watch(supportedBanksProvider);
            return banksAsync.when(
              data: (banks) {
                // Ensure current code is valid
                final isValid = _bankCode != null && 
                    banks.any((b) => b['bank_code'].toString() == _bankCode);
                
                return DropdownButtonFormField<String>(
                  key: ValueKey('bank_${isValid ? _bankCode : "null"}'),
                  initialValue: isValid ? _bankCode : null,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  items: banks.map((b) => DropdownMenuItem(
                    value: b['bank_code'].toString(),
                    child: Text(
                      b['bank_name']?.toString() ?? 'Unknown',
                      overflow: TextOverflow.ellipsis,
                    ),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                         _bankCode = val;
                         final bank = banks.firstWhere(
                           (b) => b['bank_code'].toString() == val,
                           orElse: () => {},
                         );
                         _bankNameController.text = bank['bank_name']?.toString() ?? '';
                      });
                    }
                  },
                  validator: (val) {
                     if (_paymentMethod == 'BANK' && (val == null || val.isEmpty)) {
                       return 'Please select a bank';
                     }
                     return null;
                  },
                  hint: const Text('Select Bank'),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
                validator: (val) => _paymentMethod == 'BANK' && (val?.isEmpty ?? true) ? 'Required' : null,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bankAccountController,
          decoration: const InputDecoration(
            labelText: 'Account Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.numbers),
          ),
          keyboardType: TextInputType.number,
          validator: (val) {
            if (_paymentMethod == 'BANK' && (val == null || val.isEmpty)) {
              return 'Please enter account number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMpesaFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('M-Pesa Details'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _mpesaPhoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '07...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (val) {
            if (_paymentMethod == 'MPESA' && (val == null || val.isEmpty)) {
              return 'Please enter phone number';
            }
            return null;
          },
        ),
      ],
    );
  }
}
