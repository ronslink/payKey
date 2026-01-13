import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/worker_model.dart';

import '../../../settings/providers/settings_provider.dart';
import '../providers/workers_provider.dart';

// =============================================================================
// CONSTANTS
// =============================================================================

/// App color scheme constants.
abstract class _AppColors {
  static const background = Color(0xFFF9FAFB);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF111827);
  static const primary = Color(0xFF3B82F6);
  static const success = Colors.green;
  static const error = Colors.red;
}

/// Payment frequency options.
enum PaymentFrequency {
  monthly('MONTHLY', 'Monthly'),
  weekly('WEEKLY', 'Weekly');

  final String value;
  final String label;
  const PaymentFrequency(this.value, this.label);

  static PaymentFrequency fromValue(String value) {
    return PaymentFrequency.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentFrequency.monthly,
    );
  }
}

/// Payment method options.
enum PaymentMethod {
  mpesa('MPESA', 'M-Pesa'),
  bank('BANK', 'Bank Transfer'),
  cash('CASH', 'Cash');

  final String value;
  final String label;
  const PaymentMethod(this.value, this.label);

  static PaymentMethod fromValue(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentMethod.mpesa,
    );
  }
}

// =============================================================================
// MAIN PAGE
// =============================================================================

class WorkerFormPage extends ConsumerStatefulWidget {
  final WorkerModel? worker;

  const WorkerFormPage({super.key, this.worker});

  bool get isEditing => worker != null;

  @override
  ConsumerState<WorkerFormPage> createState() => _WorkerFormPageState();
}

class _WorkerFormPageState extends ConsumerState<WorkerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _WorkerFormControllers _controllers;
  late PaymentFrequency _paymentFrequency;
  late PaymentMethod _paymentMethod;
  DateTime? _dateOfBirth;
  DateTime _startDate = DateTime.now();
  String _employmentType = 'FIXED';
  bool _isSaving = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _controllers = _WorkerFormControllers();
    _initializeFormData();
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  void _initializeFormData() {
    final worker = widget.worker;

    if (worker != null) {
      _controllers.populateFrom(worker);
      _paymentFrequency = PaymentFrequency.fromValue(worker.paymentFrequency);
      _paymentMethod = PaymentMethod.fromValue(worker.paymentMethod);
      _dateOfBirth = worker.dateOfBirth;
      _startDate = worker.startDate ?? DateTime.now();
      _employmentType = worker.employmentType;
    } else {
      _paymentFrequency = PaymentFrequency.monthly;
      _paymentMethod = PaymentMethod.mpesa;
      _startDate = DateTime.now();
      _employmentType = 'FIXED';
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _saveWorker() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(workersProvider.notifier);

      if (widget.isEditing) {
        await notifier.updateWorker(
          widget.worker!.id,
          _buildUpdateRequest(),
        );
      } else {
        await notifier.createWorker(_buildCreateRequest());
      }

      if (mounted) {
        _showSuccess(
          widget.isEditing ? 'Worker updated successfully' : 'Worker added successfully',
        );
        _navigateBack();
      }
    } catch (error) {
      if (mounted) {
        _showError('Error saving worker: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  CreateWorkerRequest _buildCreateRequest() {
    // Get default property ID from settings (only for PLATINUM users)
    final settings = ref.read(settingsProvider);
    final defaultPropertyId = settings.when(
      data: (s) => s.defaultPropertyId,
      loading: () => null,
      error: (_, __) => null,
    );
    
    return CreateWorkerRequest(
      name: _controllers.name.trimmedText,
      phoneNumber: _controllers.phone.trimmedText,
      salaryGross: _controllers.salary.doubleValue,
      startDate: _startDate,
      email: _controllers.email.nullableText,
      idNumber: _controllers.idNumber.nullableText,
      kraPin: _controllers.kraPin.nullableText,
      nssfNumber: _controllers.nssf.nullableText,
      nhifNumber: _controllers.nhif.nullableText,
      jobTitle: _controllers.jobTitle.nullableText,
      employmentType: _employmentType,
      housingAllowance: _controllers.housingAllowance.doubleValue,
      transportAllowance: _controllers.transportAllowance.doubleValue,
      paymentFrequency: _paymentFrequency.value,
      paymentMethod: _paymentMethod.value,
      mpesaNumber: _controllers.mpesaNumber.nullableText,
      bankName: _controllers.bankName.nullableText,
      bankAccount: _controllers.bankAccount.nullableText,
      notes: _controllers.notes.nullableText,
      emergencyContactName: _controllers.emergencyName.nullableText,
      emergencyContactPhone: _controllers.emergencyPhone.nullableText,
      emergencyContactRelationship: _controllers.emergencyRelationship.nullableText,
      dateOfBirth: _dateOfBirth,
      // Link worker to default property (only if PLATINUM user has one set)
      propertyId: defaultPropertyId,
    );
  }

  UpdateWorkerRequest _buildUpdateRequest() {
    return UpdateWorkerRequest(
      name: _controllers.name.trimmedText,
      phoneNumber: _controllers.phone.trimmedText,
      salaryGross: _controllers.salary.doubleValue,
      startDate: _startDate,
      email: _controllers.email.nullableText,
      idNumber: _controllers.idNumber.nullableText,
      kraPin: _controllers.kraPin.nullableText,
      nssfNumber: _controllers.nssf.nullableText,
      nhifNumber: _controllers.nhif.nullableText,
      jobTitle: _controllers.jobTitle.nullableText,
      employmentType: _employmentType,
      housingAllowance: _controllers.housingAllowance.doubleValue,
      transportAllowance: _controllers.transportAllowance.doubleValue,
      paymentFrequency: _paymentFrequency.value,
      paymentMethod: _paymentMethod.value,
      mpesaNumber: _controllers.mpesaNumber.nullableText,
      bankName: _controllers.bankName.nullableText,
      bankAccount: _controllers.bankAccount.nullableText,
      notes: _controllers.notes.nullableText,
      emergencyContactName: _controllers.emergencyName.nullableText,
      emergencyContactPhone: _controllers.emergencyPhone.nullableText,
      emergencyContactRelationship: _controllers.emergencyRelationship.nullableText,
      dateOfBirth: _dateOfBirth,
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation & Feedback
  // ---------------------------------------------------------------------------

  void _navigateBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/workers');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: _AppColors.success),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: _AppColors.error),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PersonalInfoSection(
                controllers: _controllers,
                dateOfBirth: _dateOfBirth,
                onDateOfBirthChanged: (date) => setState(() => _dateOfBirth = date),
              ),
              const SizedBox(height: 24),
              _EmergencyContactSection(controllers: _controllers),
              const SizedBox(height: 24),
              _StatutoryDetailsSection(controllers: _controllers),
              const SizedBox(height: 24),
              _EmploymentDetailsSection(
                controllers: _controllers,
                startDate: _startDate,
                onStartDateChanged: (date) => setState(() => _startDate = date),
                employmentType: _employmentType,
                onEmploymentTypeChanged: (type) => setState(() => _employmentType = type),
              ),
              const SizedBox(height: 24),
              _PaymentDetailsSection(
                controllers: _controllers,
                paymentFrequency: _paymentFrequency,
                paymentMethod: _paymentMethod,
                onFrequencyChanged: (v) => setState(() => _paymentFrequency = v),
                onMethodChanged: (v) => setState(() => _paymentMethod = v),
              ),
              const SizedBox(height: 24),
              _NotesSection(controller: _controllers.notes),
              const SizedBox(height: 32),
              _SubmitButton(
                isEditing: widget.isEditing,
                isSaving: _isSaving,
                onPressed: _saveWorker,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _AppColors.surface,
      foregroundColor: _AppColors.textPrimary,
      elevation: 0,
      title: Text(
        widget.isEditing ? 'Edit Worker' : 'Add Worker',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: _navigateBack,
      ),
    );
  }
}

// =============================================================================
// FORM CONTROLLERS
// =============================================================================

/// Manages all TextEditingControllers for the worker form.
class _WorkerFormControllers {
  // Personal Info
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final idNumber = TextEditingController();

  // Statutory Details
  final kraPin = TextEditingController();
  final nssf = TextEditingController();
  final nhif = TextEditingController();

  // Employment Details
  final jobTitle = TextEditingController();
  final salary = TextEditingController();
  final housingAllowance = TextEditingController();
  final transportAllowance = TextEditingController();

  // Payment Details
  final mpesaNumber = TextEditingController();
  final bankName = TextEditingController();
  final bankAccount = TextEditingController();

  // Notes
  final notes = TextEditingController();

  // Emergency Contact
  final emergencyName = TextEditingController();
  final emergencyPhone = TextEditingController();
  final emergencyRelationship = TextEditingController();

  /// Populate controllers from an existing worker model.
  void populateFrom(WorkerModel worker) {
    name.text = worker.name;
    phone.text = worker.phoneNumber;
    email.text = worker.email ?? '';
    idNumber.text = worker.idNumber ?? '';

    kraPin.text = worker.kraPin ?? '';
    nssf.text = worker.nssfNumber ?? '';
    nhif.text = worker.nhifNumber ?? '';

    jobTitle.text = worker.jobTitle ?? '';
    salary.text = worker.salaryGross.toString();
    housingAllowance.text = worker.housingAllowance.toString();
    transportAllowance.text = worker.transportAllowance.toString();

    mpesaNumber.text = worker.mpesaNumber ?? '';
    bankName.text = worker.bankName ?? '';
    bankAccount.text = worker.bankAccount ?? '';

    notes.text = worker.notes ?? '';
    
    emergencyName.text = worker.emergencyContactName ?? '';
    emergencyPhone.text = worker.emergencyContactPhone ?? '';
    emergencyRelationship.text = worker.emergencyContactRelationship ?? '';
  }

  /// Dispose all controllers.
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    idNumber.dispose();
    kraPin.dispose();
    nssf.dispose();
    nhif.dispose();
    jobTitle.dispose();
    salary.dispose();
    housingAllowance.dispose();
    transportAllowance.dispose();
    mpesaNumber.dispose();
    bankName.dispose();
    bankAccount.dispose();
    notes.dispose();
    emergencyName.dispose();
    emergencyPhone.dispose();
    emergencyRelationship.dispose();
  }
}

/// Extension for convenient text extraction from controllers.
extension _TextEditingControllerExt on TextEditingController {
  String get trimmedText => text.trim();

  String? get nullableText {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  double get doubleValue => double.tryParse(text.trim()) ?? 0;
}

// =============================================================================
// FORM SECTIONS
// =============================================================================

// -----------------------------------------------------------------------------
// Personal Info Section
// -----------------------------------------------------------------------------

class _PersonalInfoSection extends StatelessWidget {
  final _WorkerFormControllers controllers;
  final DateTime? dateOfBirth;
  final ValueChanged<DateTime?> onDateOfBirthChanged;

  const _PersonalInfoSection({
    required this.controllers,
    required this.dateOfBirth,
    required this.onDateOfBirthChanged,
  });

  int? get _age {
    if (dateOfBirth == null) return null;
    final today = DateTime.now();
    int age = today.year - dateOfBirth!.year;
    if (today.month < dateOfBirth!.month ||
        (today.month == dateOfBirth!.month && today.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: 'Personal Information',
      children: [
        _FormTextField(
          controller: controllers.name,
          label: 'Full Name',
          hint: 'Enter full name',
          isRequired: true,
        ),
        _FormTextField(
          controller: controllers.phone,
          label: 'Phone Number',
          hint: 'Enter phone number',
          keyboardType: TextInputType.phone,
          isRequired: true,
        ),
        _FormTextField(
          controller: controllers.email,
          label: 'Email',
          hint: 'Enter email address',
          keyboardType: TextInputType.emailAddress,
        ),
        _FormTextField(
          controller: controllers.idNumber,
          label: 'ID Number',
          hint: 'Enter National ID',
        ),
        // Date of Birth Picker
        _buildDateOfBirthField(context),
      ],
    );
  }

  Widget _buildDateOfBirthField(BuildContext context) {
    final displayText = dateOfBirth != null
        ? '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}'
        : 'Select date of birth';
    
    final ageText = _age != null ? ' (Age: $_age)' : '';
    final isUnderAge = _age != null && _age! < 13;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date of Birth$ageText',
              hintText: 'Select date of birth',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: _AppColors.background,
              suffixIcon: const Icon(Icons.calendar_today),
              errorText: isUnderAge 
                  ? 'Worker must be at least 13 years old (Kenya Labor Law)' 
                  : null,
            ),
            child: Text(
              displayText,
              style: TextStyle(
                color: dateOfBirth == null ? Colors.grey : _AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 13, now.month, now.day), // Max age 13+
      helpText: 'Select Date of Birth',
    );
    if (picked != null) {
      onDateOfBirthChanged(picked);
    }
  }
}

// -----------------------------------------------------------------------------
// Emergency Contact Section
// -----------------------------------------------------------------------------

class _EmergencyContactSection extends StatelessWidget {
  final _WorkerFormControllers controllers;

  const _EmergencyContactSection({required this.controllers});

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: 'Emergency Contact',
      children: [
        _FormTextField(
          controller: controllers.emergencyName,
          label: 'Contact Name',
          hint: 'Full Name',
        ),
        _FormTextField(
          controller: controllers.emergencyPhone,
          label: 'Phone Number',
          hint: 'Contact Phone Number',
          keyboardType: TextInputType.phone,
        ),
        _FormTextField(
          controller: controllers.emergencyRelationship,
          label: 'Relationship',
          hint: 'e.g. Spouse, Sibling',
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Statutory Details Section
// -----------------------------------------------------------------------------

class _StatutoryDetailsSection extends StatelessWidget {
  final _WorkerFormControllers controllers;

  const _StatutoryDetailsSection({required this.controllers});

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: 'Statutory Details',
      children: [
        _FormTextField(
          controller: controllers.kraPin,
          label: 'KRA PIN',
          hint: 'Enter KRA PIN',
        ),
        _FormTextField(
          controller: controllers.nssf,
          label: 'NSSF Number',
          hint: 'Enter NSSF Number',
        ),
        _FormTextField(
          controller: controllers.nhif,
          label: 'NHIF Number',
          hint: 'Enter NHIF Number',
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Employment Details Section
// -----------------------------------------------------------------------------

class _EmploymentDetailsSection extends StatelessWidget {
  final _WorkerFormControllers controllers;
  final DateTime startDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final String employmentType;
  final ValueChanged<String> onEmploymentTypeChanged;

  const _EmploymentDetailsSection({
    required this.controllers,
    required this.startDate,
    required this.onStartDateChanged,
    required this.employmentType,
    required this.onEmploymentTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: 'Employment Details',
      children: [
        _FormTextField(
          controller: controllers.jobTitle,
          label: 'Job Title',
          hint: 'e.g. Housekeeper, Gardener',
        ),
        
        // Employment Type Dropdown
        DropdownButtonFormField<String>(
          initialValue: employmentType,
          decoration: const InputDecoration(
            labelText: 'Employment Type',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: _AppColors.background,
          ),
          items: const [
            DropdownMenuItem(value: 'FIXED', child: Text('Fixed Salary')),
            DropdownMenuItem(value: 'HOURLY', child: Text('Hourly Rate')),
          ],
          onChanged: (value) {
            if (value != null) onEmploymentTypeChanged(value);
          },
        ),
        // Start Date Field
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: startDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              helpText: 'Select Start Date',
            );
            if (picked != null) {
              onStartDateChanged(picked);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Start Date',
              hintText: 'Select start date',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: _AppColors.background,
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              '${startDate.day}/${startDate.month}/${startDate.year}',
              style: const TextStyle(color: _AppColors.textPrimary),
            ),
          ),
        ),

        _FormTextField(
          controller: controllers.salary,
          label: 'Basic Salary (KES)',
          hint: '0.00',
          keyboardType: TextInputType.number,
          isRequired: true,
        ),
        Row(
          children: [
            Expanded(
              child: _FormTextField(
                controller: controllers.housingAllowance,
                label: 'Housing Allowance',
                hint: '0.00',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _FormTextField(
                controller: controllers.transportAllowance,
                label: 'Transport Allowance',
                hint: '0.00',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Payment Details Section
// -----------------------------------------------------------------------------

class _PaymentDetailsSection extends StatelessWidget {
  final _WorkerFormControllers controllers;
  final PaymentFrequency paymentFrequency;
  final PaymentMethod paymentMethod;
  final ValueChanged<PaymentFrequency> onFrequencyChanged;
  final ValueChanged<PaymentMethod> onMethodChanged;

  const _PaymentDetailsSection({
    required this.controllers,
    required this.paymentFrequency,
    required this.paymentMethod,
    required this.onFrequencyChanged,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: 'Payment Details',
      children: [
        _FormDropdown<PaymentFrequency>(
          label: 'Payment Frequency',
          value: paymentFrequency,
          items: PaymentFrequency.values,
          itemLabel: (e) => e.label,
          onChanged: onFrequencyChanged,
        ),
        _FormDropdown<PaymentMethod>(
          label: 'Payment Method',
          value: paymentMethod,
          items: PaymentMethod.values,
          itemLabel: (e) => e.label,
          onChanged: onMethodChanged,
        ),
        _PaymentMethodFields(
          method: paymentMethod,
          controllers: controllers,
        ),
      ],
    );
  }
}

class _PaymentMethodFields extends StatelessWidget {
  final PaymentMethod method;
  final _WorkerFormControllers controllers;

  const _PaymentMethodFields({
    required this.method,
    required this.controllers,
  });

  @override
  Widget build(BuildContext context) {
    return switch (method) {
      PaymentMethod.mpesa => _FormTextField(
          controller: controllers.mpesaNumber,
          label: 'M-Pesa Number',
          hint: 'Enter M-Pesa number',
          keyboardType: TextInputType.phone,
        ),
      PaymentMethod.bank => Column(
          children: [
            _FormTextField(
              controller: controllers.bankName,
              label: 'Bank Name',
              hint: 'Enter bank name',
            ),
            const SizedBox(height: 16),
            _FormTextField(
              controller: controllers.bankAccount,
              label: 'Account Number',
              hint: 'Enter account number',
            ),
          ],
        ),
      PaymentMethod.cash => const SizedBox.shrink(),
    };
  }
}

// -----------------------------------------------------------------------------
// Notes Section
// -----------------------------------------------------------------------------

class _NotesSection extends StatelessWidget {
  final TextEditingController controller;

  const _NotesSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: 'Notes',
      children: [
        _FormTextField(
          controller: controller,
          label: 'Additional Notes',
          hint: 'Any other details...',
          maxLines: 3,
        ),
      ],
    );
  }
}

// =============================================================================
// REUSABLE FORM WIDGETS
// =============================================================================

// -----------------------------------------------------------------------------
// Form Section Container
// -----------------------------------------------------------------------------

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              color: _AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          ..._insertSpacing(children),
        ],
      ),
    );
  }

  List<Widget> _insertSpacing(List<Widget> widgets) {
    if (widgets.isEmpty) return widgets;

    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(const SizedBox(height: 16));
      }
    }
    return result;
  }
}

// -----------------------------------------------------------------------------
// Form Text Field
// -----------------------------------------------------------------------------

class _FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final bool isRequired;
  final int maxLines;

  const _FormTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.isRequired = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: _AppColors.background,
      ),
      validator: isRequired ? _requiredValidator : null,
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }
}

// -----------------------------------------------------------------------------
// Form Dropdown
// -----------------------------------------------------------------------------

class _FormDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  const _FormDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: _AppColors.background,
      ),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item)),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Submit Button
// -----------------------------------------------------------------------------

class _SubmitButton extends StatelessWidget {
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isEditing,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isSaving ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              isEditing ? 'Update Worker' : 'Add Worker',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
