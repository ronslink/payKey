import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';

// ============================================================================
// Constants
// ============================================================================

class _LeaveColors {
  static const primary = Color(0xFF6366F1);
  static const background = Color(0xFFF8FAFC);
  static const text = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF374151);
}

class _LeaveStyles {
  static const cardRadius = 12.0;
  static const pagePadding = 20.0;

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      );

  static OutlineInputBorder inputBorder([Color? color]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: BorderSide(
          color: color ?? Colors.grey[300]!,
          width: color != null ? 2 : 1,
        ),
      );
}

// ============================================================================
// Leave Type Enum
// ============================================================================

enum LeaveType {
  annual('ANNUAL', 'Annual Leave'),
  sick('SICK', 'Sick Leave'),
  maternity('MATERNITY', 'Maternity Leave'),
  paternity('PATERNITY', 'Paternity Leave'),
  emergency('EMERGENCY', 'Emergency Leave'),
  unpaid('UNPAID', 'Unpaid Leave');

  final String value;
  final String label;
  const LeaveType(this.value, this.label);
}

// ============================================================================
// Date Formatter
// ============================================================================

class _DateFormatter {
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  static String format(DateTime date) => '${_months[date.month - 1]} ${date.day}, ${date.year}';

  static String toIsoDate(DateTime date) => date.toIso8601String().split('T')[0];
}

// ============================================================================
// Main Page Widget
// ============================================================================

class RequestLeavePage extends ConsumerStatefulWidget {
  const RequestLeavePage({super.key});

  @override
  ConsumerState<RequestLeavePage> createState() => _RequestLeavePageState();
}

class _RequestLeavePageState extends ConsumerState<RequestLeavePage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  LeaveType _selectedLeaveType = LeaveType.annual;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  int get _totalDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Date Selection
  // --------------------------------------------------------------------------

  Future<void> _selectDate(bool isStartDate) async {
    final now = DateTime.now();
    final initialDate = isStartDate
        ? (_startDate ?? now.add(const Duration(days: 1)))
        : (_endDate ?? _startDate ?? now.add(const Duration(days: 1)));

    final firstDate = isStartDate ? now : (_startDate ?? now);

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _LeaveColors.primary),
        ),
        child: child!,
      ),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
          if (_endDate != null && _endDate!.isBefore(date)) {
            _endDate = date;
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  // --------------------------------------------------------------------------
  // Form Submission
  // --------------------------------------------------------------------------

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      _showSnackBar('Please select start and end dates', Colors.orange);
      return;
    }

    _setSubmitting(true);

    try {
      final response = await ApiService().employeePortal.requestLeave(
        leaveType: _selectedLeaveType.value,
        startDate: _DateFormatter.toIsoDate(_startDate!),
        endDate: _DateFormatter.toIsoDate(_endDate!),
        reason: _reasonController.text.isNotEmpty ? _reasonController.text : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Leave request submitted successfully!', Colors.green);
        if (mounted) context.pop();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to submit request');
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      _setSubmitting(false);
    }
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  void _setSubmitting(bool value) {
    if (mounted) setState(() => _isSubmitting = value);
  }

  void _showSnackBar(String message, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _onLeaveTypeSelected(LeaveType type) {
    setState(() => _selectedLeaveType = type);
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LeaveColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(_LeaveStyles.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLeaveTypeSection(),
              const SizedBox(height: 24),
              _buildDateSection(),
              if (_totalDays > 0) ...[
                const SizedBox(height: 16),
                _TotalDaysBadge(days: _totalDays),
              ],
              const SizedBox(height: 24),
              _buildReasonSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _LeaveColors.text),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Request Leave',
        style: TextStyle(color: _LeaveColors.text, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildLeaveTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Leave Type'),
        const SizedBox(height: 12),
        _LeaveTypeSelector(
          selectedType: _selectedLeaveType,
          onTypeSelected: _onLeaveTypeSelected,
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Dates'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'Start Date',
                date: _startDate,
                onTap: () => _selectDate(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateField(
                label: 'End Date',
                date: _endDate,
                onTap: () => _selectDate(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Reason (Optional)'),
        const SizedBox(height: 12),
        _ReasonTextField(controller: _reasonController),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return _SubmitButton(
      isSubmitting: _isSubmitting,
      onPressed: _submitRequest,
    );
  }
}

// ============================================================================
// Section Title
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _LeaveColors.textSecondary,
      ),
    );
  }
}

// ============================================================================
// Leave Type Selector
// ============================================================================

class _LeaveTypeSelector extends StatelessWidget {
  final LeaveType selectedType;
  final ValueChanged<LeaveType> onTypeSelected;

  const _LeaveTypeSelector({
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _LeaveStyles.cardDecoration,
      child: Column(
        children: LeaveType.values.map((type) {
          final isLast = type == LeaveType.values.last;
          return _LeaveTypeOption(
            type: type,
            isSelected: selectedType == type,
            showBorder: !isLast,
            onTap: () => onTypeSelected(type),
          );
        }).toList(),
      ),
    );
  }
}

class _LeaveTypeOption extends StatelessWidget {
  final LeaveType type;
  final bool isSelected;
  final bool showBorder;
  final VoidCallback onTap;

  const _LeaveTypeOption({
    required this.type,
    required this.isSelected,
    required this.showBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(bottom: BorderSide(color: Colors.grey[200]!))
              : null,
        ),
        child: Row(
          children: [
            _RadioIndicator(isSelected: isSelected),
            const SizedBox(width: 12),
            Text(
              type.label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _LeaveColors.primary : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  final bool isSelected;

  const _RadioIndicator({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? _LeaveColors.primary : Colors.grey[400]!,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _LeaveColors.primary,
                ),
              ),
            )
          : null,
    );
  }
}

// ============================================================================
// Date Field
// ============================================================================

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  bool get _hasDate => date != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_LeaveStyles.cardRadius),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: _hasDate ? _LeaveColors.primary : Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Text(
                  _hasDate ? _DateFormatter.format(date!) : 'Select',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _hasDate ? _LeaveColors.text : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Total Days Badge
// ============================================================================

class _TotalDaysBadge extends StatelessWidget {
  final int days;

  const _TotalDaysBadge({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _LeaveColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_LeaveStyles.cardRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, color: _LeaveColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            '$days day${days > 1 ? 's' : ''} requested',
            style: const TextStyle(
              color: _LeaveColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Reason Text Field
// ============================================================================

class _ReasonTextField extends StatelessWidget {
  final TextEditingController controller;

  const _ReasonTextField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Enter reason for leave...',
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        border: _LeaveStyles.inputBorder(),
        enabledBorder: _LeaveStyles.inputBorder(),
        focusedBorder: _LeaveStyles.inputBorder(_LeaveColors.primary),
      ),
    );
  }
}

// ============================================================================
// Submit Button
// ============================================================================

class _SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isSubmitting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isSubmitting ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _LeaveColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_LeaveStyles.cardRadius),
        ),
        elevation: 0,
      ),
      child: isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Text(
              'Submit Request',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }
}