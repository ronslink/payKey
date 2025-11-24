import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/worker_model.dart';
import '../providers/workers_provider.dart';

class WorkerFormPage extends ConsumerStatefulWidget {
  final WorkerModel? worker;

  const WorkerFormPage({super.key, this.worker});

  @override
  ConsumerState<WorkerFormPage> createState() => _WorkerFormPageState();
}

class _WorkerFormPageState extends ConsumerState<WorkerFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Personal Info
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _kraPinController = TextEditingController();
  final _nssfController = TextEditingController();
  final _nhifController = TextEditingController();
  
  // Employment Details
  final _jobTitleController = TextEditingController();
  final _salaryController = TextEditingController();
  final _housingAllowanceController = TextEditingController();
  final _transportAllowanceController = TextEditingController();
  
  // Payment Details
  String _paymentFrequency = 'MONTHLY';
  String _paymentMethod = 'MPESA';
  final _mpesaNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.worker != null) {
      final w = widget.worker!;
      _nameController.text = w.name;
      _phoneController.text = w.phoneNumber;
      _emailController.text = w.email ?? '';
      _idNumberController.text = w.idNumber ?? '';
      _kraPinController.text = w.kraPin ?? '';
      _nssfController.text = w.nssfNumber ?? '';
      _nhifController.text = w.nhifNumber ?? '';
      
      _jobTitleController.text = w.jobTitle ?? '';
      _salaryController.text = w.salaryGross.toString();
      _housingAllowanceController.text = w.housingAllowance.toString();
      _transportAllowanceController.text = w.transportAllowance.toString();
      
      _paymentFrequency = w.paymentFrequency;
      _paymentMethod = w.paymentMethod;
      _mpesaNumberController.text = w.mpesaNumber ?? '';
      _bankNameController.text = w.bankName ?? '';
      _bankAccountController.text = w.bankAccount ?? '';
      
      _notesController.text = w.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _idNumberController.dispose();
    _kraPinController.dispose();
    _nssfController.dispose();
    _nhifController.dispose();
    _jobTitleController.dispose();
    _salaryController.dispose();
    _housingAllowanceController.dispose();
    _transportAllowanceController.dispose();
    _mpesaNumberController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveWorker() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final notifier = ref.read(workersProvider.notifier);

    try {
      final double salary = double.parse(_salaryController.text.trim());
      final double housing = double.tryParse(_housingAllowanceController.text.trim()) ?? 0;
      final double transport = double.tryParse(_transportAllowanceController.text.trim()) ?? 0;

      if (widget.worker == null) {
        // Create new worker
        await notifier.createWorker(
          CreateWorkerRequest(
            name: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            salaryGross: salary,
            startDate: DateTime.now(),
            email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
            idNumber: _idNumberController.text.trim().isEmpty ? null : _idNumberController.text.trim(),
            kraPin: _kraPinController.text.trim().isEmpty ? null : _kraPinController.text.trim(),
            nssfNumber: _nssfController.text.trim().isEmpty ? null : _nssfController.text.trim(),
            nhifNumber: _nhifController.text.trim().isEmpty ? null : _nhifController.text.trim(),
            jobTitle: _jobTitleController.text.trim().isEmpty ? null : _jobTitleController.text.trim(),
            housingAllowance: housing,
            transportAllowance: transport,
            paymentFrequency: _paymentFrequency,
            paymentMethod: _paymentMethod,
            mpesaNumber: _mpesaNumberController.text.trim().isEmpty ? null : _mpesaNumberController.text.trim(),
            bankName: _bankNameController.text.trim().isEmpty ? null : _bankNameController.text.trim(),
            bankAccount: _bankAccountController.text.trim().isEmpty ? null : _bankAccountController.text.trim(),
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          ),
        );
      } else {
        // Update existing worker
        await notifier.updateWorker(
          widget.worker!.id,
          UpdateWorkerRequest(
            name: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            salaryGross: salary,
            email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
            idNumber: _idNumberController.text.trim().isEmpty ? null : _idNumberController.text.trim(),
            kraPin: _kraPinController.text.trim().isEmpty ? null : _kraPinController.text.trim(),
            nssfNumber: _nssfController.text.trim().isEmpty ? null : _nssfController.text.trim(),
            nhifNumber: _nhifController.text.trim().isEmpty ? null : _nhifController.text.trim(),
            jobTitle: _jobTitleController.text.trim().isEmpty ? null : _jobTitleController.text.trim(),
            housingAllowance: housing,
            transportAllowance: transport,
            paymentFrequency: _paymentFrequency,
            paymentMethod: _paymentMethod,
            mpesaNumber: _mpesaNumberController.text.trim().isEmpty ? null : _mpesaNumberController.text.trim(),
            bankName: _bankNameController.text.trim().isEmpty ? null : _bankNameController.text.trim(),
            bankAccount: _bankAccountController.text.trim().isEmpty ? null : _bankAccountController.text.trim(),
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          ),
        );
      }

      if (mounted) {
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving worker: $error'),
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
        title: Text(
          widget.worker == null ? 'Add Worker' : 'Edit Worker',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSection(
                'Personal Information',
                [
                  _buildTextField(_nameController, 'Full Name', 'Enter full name', required: true),
                  const SizedBox(height: 16),
                  _buildTextField(_phoneController, 'Phone Number', 'Enter phone number', inputType: TextInputType.phone, required: true),
                  const SizedBox(height: 16),
                  _buildTextField(_emailController, 'Email', 'Enter email address', inputType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildTextField(_idNumberController, 'ID Number', 'Enter National ID'),
                ],
              ),
              const SizedBox(height: 24),
              
              _buildSection(
                'Statutory Details',
                [
                  _buildTextField(_kraPinController, 'KRA PIN', 'Enter KRA PIN'),
                  const SizedBox(height: 16),
                  _buildTextField(_nssfController, 'NSSF Number', 'Enter NSSF Number'),
                  const SizedBox(height: 16),
                  _buildTextField(_nhifController, 'NHIF Number', 'Enter NHIF Number'),
                ],
              ),
              const SizedBox(height: 24),

              _buildSection(
                'Employment Details',
                [
                  _buildTextField(_jobTitleController, 'Job Title', 'e.g. Housekeeper, Gardener'),
                  const SizedBox(height: 16),
                  _buildTextField(_salaryController, 'Basic Salary (KES)', '0.00', inputType: TextInputType.number, required: true),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_housingAllowanceController, 'Housing Allowance', '0.00', inputType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(_transportAllowanceController, 'Transport Allowance', '0.00', inputType: TextInputType.number)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSection(
                'Payment Details',
                [
                  DropdownButtonFormField<String>(
                    value: _paymentFrequency,
                    decoration: const InputDecoration(
                      labelText: 'Payment Frequency',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFF9FAFB),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                      DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                    ],
                    onChanged: (value) => setState(() => _paymentFrequency = value!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFF9FAFB),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'MPESA', child: Text('M-Pesa')),
                      DropdownMenuItem(value: 'BANK', child: Text('Bank Transfer')),
                      DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                    ],
                    onChanged: (value) => setState(() => _paymentMethod = value!),
                  ),
                  const SizedBox(height: 16),
                  if (_paymentMethod == 'MPESA')
                    _buildTextField(_mpesaNumberController, 'M-Pesa Number', 'Enter M-Pesa number', inputType: TextInputType.phone),
                  if (_paymentMethod == 'BANK') ...[
                    _buildTextField(_bankNameController, 'Bank Name', 'Enter bank name'),
                    const SizedBox(height: 16),
                    _buildTextField(_bankAccountController, 'Account Number', 'Enter account number'),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              _buildSection(
                'Notes',
                [
                  _buildTextField(_notesController, 'Additional Notes', 'Any other details...', maxLines: 3),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saveWorker,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.worker == null ? 'Add Worker' : 'Update Worker',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType inputType = TextInputType.text,
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
      ),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return '$label is required';
        }
        return null;
      },
    );
  }
}
