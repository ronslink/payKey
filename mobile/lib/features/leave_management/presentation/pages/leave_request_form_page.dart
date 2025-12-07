import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/leave_request_model.dart';
import '../providers/leave_management_provider.dart';

class LeaveRequestFormPage extends ConsumerStatefulWidget {
  final String workerId;
  final VoidCallback? onSubmitted;

  const LeaveRequestFormPage({
    super.key,
    required this.workerId,
    this.onSubmitted,
  });

  @override
  ConsumerState<LeaveRequestFormPage> createState() => _LeaveRequestFormPageState();
}

class _LeaveRequestFormPageState extends ConsumerState<LeaveRequestFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  
LeaveType _selectedLeaveType = LeaveType.annual;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isPaidLeave = true;
  double? _dailyPayRate;

  @override
  void dispose() {
    _reasonController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Leave'),
        actions: [
          TextButton(
            onPressed: _submitForm,
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leave Type Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Leave Type',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<LeaveType>(
                        initialValue: _selectedLeaveType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: LeaveType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getLeaveTypeDisplayName(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLeaveType = value!;
                            // Auto-adjust paid leave based on type
                            _isPaidLeave = _selectedLeaveType != LeaveType.unpaid;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Date Range Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Leave Period',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              'Start Date',
                              _startDate,
                              (date) => setState(() => _startDate = date),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateField(
                              'End Date',
                              _endDate,
                              (date) => setState(() => _endDate = date),
                            ),
                          ),
                        ],
                      ),
                      if (_startDate != null && _endDate != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Total Days: ${_calculateTotalDays()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Reason
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Please provide a reason for your leave request',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please provide a reason';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Payment Options
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Options',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Paid Leave'),
                        subtitle: const Text('Leave will be paid according to daily rate'),
                        value: _isPaidLeave,
                        onChanged: (value) {
                          setState(() {
                            _isPaidLeave = value ?? true;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (_isPaidLeave) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Daily Pay Rate (Optional)',
                            prefixText: '\$ ',
                            hintText: 'Leave blank to use default rate',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _dailyPayRate = value.isNotEmpty ? double.parse(value) : null;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Emergency Contact (for longer leaves)
              if (_calculateTotalDays() > 3)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Emergency Contact',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emergencyContactController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Emergency Contact Name',
                            hintText: 'Who should we contact in case of emergency?',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emergencyPhoneController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Emergency Contact Phone',
                            hintText: '+1234567890',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit Leave Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? date,
    void Function(DateTime?) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (selectedDate != null) {
          onChanged(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null 
                    ? DateFormat('MMM dd, yyyy').format(date)
                    : label,
                style: TextStyle(
                  color: date != null ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ),
            if (date != null)
              IconButton(
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.clear, size: 18),
              ),
          ],
        ),
      ),
    );
  }

String _getLeaveTypeDisplayName(LeaveType type) {
    switch (type) {
      case LeaveType.annual:
        return 'Annual Leave';
      case LeaveType.sick:
        return 'Sick Leave';
      case LeaveType.maternity:
        return 'Maternity Leave';
      case LeaveType.paternity:
        return 'Paternity Leave';
      case LeaveType.emergency:
        return 'Emergency Leave';
      case LeaveType.unpaid:
        return 'Unpaid Leave';
    }
  }

  int _calculateTotalDays() {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start date cannot be after end date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    final totalDays = _calculateTotalDays();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Leave Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${_getLeaveTypeDisplayName(_selectedLeaveType)}'),
            Text('Start: ${DateFormat('MMM dd, yyyy').format(_startDate!)}'),
            Text('End: ${DateFormat('MMM dd, yyyy').format(_endDate!)}'),
            Text('Total Days: $totalDays'),
            Text('Paid Leave: ${_isPaidLeave ? 'Yes' : 'No'}'),
            if (_isPaidLeave && _dailyPayRate != null)
              Text('Daily Rate: \$${_dailyPayRate!.toStringAsFixed(2)}'),
            Text('Reason: ${_reasonController.text}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createLeaveRequest();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _createLeaveRequest() async {
    try {
      final leaveRequestData = {
        'leaveType': _selectedLeaveType.name,
        'startDate': DateFormat('yyyy-MM-dd').format(_startDate!),
        'endDate': DateFormat('yyyy-MM-dd').format(_endDate!),
        'reason': _reasonController.text.trim(),
        'paidLeave': _isPaidLeave,
        if (_dailyPayRate != null) 'dailyPayRate': _dailyPayRate!,
        if (_emergencyContactController.text.isNotEmpty)
          'emergencyContact': _emergencyContactController.text.trim(),
        if (_emergencyPhoneController.text.isNotEmpty)
          'emergencyPhone': _emergencyPhoneController.text.trim(),
      };

      await ref.read(leaveManagementProvider.notifier)
          .createLeaveRequest(widget.workerId, leaveRequestData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        widget.onSubmitted?.call();
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit leave request: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}