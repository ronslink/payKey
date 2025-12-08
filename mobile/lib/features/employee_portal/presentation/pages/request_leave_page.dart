import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';

/// Leave types available for employees
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

/// Page for employees to request leave
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

  Future<void> _selectDate(bool isStartDate) async {
    final initialDate = isStartDate 
        ? (_startDate ?? DateTime.now().add(const Duration(days: 1)))
        : (_endDate ?? _startDate ?? DateTime.now().add(const Duration(days: 1)));
    
    final firstDate = isStartDate 
        ? DateTime.now()
        : (_startDate ?? DateTime.now());

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
          // Reset end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(date)) {
            _endDate = date;
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end dates'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService().employeePortal.requestLeave(
        leaveType: _selectedLeaveType.value,
        startDate: _startDate!.toIso8601String().split('T')[0],
        endDate: _endDate!.toIso8601String().split('T')[0],
        reason: _reasonController.text.isNotEmpty ? _reasonController.text : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Leave request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to submit request');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Request Leave',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Leave Type Selection
              _buildSectionTitle('Leave Type'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: LeaveType.values.map((type) {
                    final isSelected = _selectedLeaveType == type;
                    return InkWell(
                      onTap: () => setState(() => _selectedLeaveType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: type != LeaveType.values.last
                                ? BorderSide(color: Colors.grey[200]!)
                                : BorderSide.none,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected 
                                      ? const Color(0xFF6366F1) 
                                      : Colors.grey[400]!,
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
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              type.label,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected 
                                    ? const Color(0xFF6366F1) 
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Date Selection
              _buildSectionTitle('Dates'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      'Start Date',
                      _startDate,
                      () => _selectDate(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField(
                      'End Date',
                      _endDate,
                      () => _selectDate(false),
                    ),
                  ),
                ],
              ),

              // Total days display
              if (_totalDays > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_totalDays day${_totalDays > 1 ? 's' : ''} requested',
                        style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Reason
              _buildSectionTitle('Reason (Optional)'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter reason for leave...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: date != null ? const Color(0xFF6366F1) : Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Text(
                  date != null ? _formatDate(date) : 'Select',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: date != null ? const Color(0xFF1E293B) : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
