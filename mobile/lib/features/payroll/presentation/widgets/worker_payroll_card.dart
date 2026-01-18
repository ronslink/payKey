import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../workers/data/models/worker_model.dart';
import '../constants/payroll_constants.dart';
import '../utils/payroll_calculator.dart';

/// Card widget for displaying a worker's payroll input form
class WorkerPayrollCard extends StatelessWidget {
  final WorkerModel worker;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final bool isExpanded;
  final TextEditingController hoursController;
  final TextEditingController overtimeController;
  final TextEditingController bonusesController;
  final TextEditingController deductionsController;
  final TextEditingController daysWorkedController;
  final int totalDaysInPeriod;
  final bool isPartialPeriod;
  final NumberFormat formatter;
  final VoidCallback onTap;
  final VoidCallback onInputChanged;

  const WorkerPayrollCard({
    super.key,
    required this.worker,
    required this.isExpanded,
    required this.hoursController,
    required this.overtimeController,
    required this.bonusesController,
    required this.deductionsController,
    required this.daysWorkedController,
    required this.totalDaysInPeriod,
    required this.isPartialPeriod,
    required this.formatter,
    required this.onTap,
    required this.onInputChanged,
    this.isSelected = true,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isHourly = worker.employmentType == EmploymentType.hourly;
    final daysWorked = int.tryParse(daysWorkedController.text) ?? totalDaysInPeriod;
    final prorationFactor = isHourly ? 1.0 : daysWorked / totalDaysInPeriod;
    
    final estimatedPay = PayrollCalculator.calculateEstimatedPay(
      worker: worker,
      hours: double.tryParse(hoursController.text) ?? 0,
      overtime: double.tryParse(overtimeController.text) ?? 0,
      bonuses: double.tryParse(bonusesController.text) ?? 0,
      deductions: double.tryParse(deductionsController.text) ?? 0,
      prorationFactor: prorationFactor,
    );

    final initials = _getInitials(worker.name);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded 
                ? Theme.of(context).primaryColor 
                : (isPartialPeriod ? Colors.orange.shade300 : Colors.grey.shade200),
            width: isPartialPeriod ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context, initials, estimatedPay, isHourly),
            if (isPartialPeriod && !isExpanded) _buildPartialBadge(),
            if (isExpanded && isSelected) ...[
              const Divider(height: 24),
              _buildInputFields(context, isHourly),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPartialBadge() {
    final daysWorked = int.tryParse(daysWorkedController.text) ?? totalDaysInPeriod;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 12, color: Colors.orange.shade700),
            const SizedBox(width: 4),
            Text(
              '$daysWorked / $totalDaysInPeriod days',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String initials,
    double estimatedPay,
    bool isHourly,
  ) {
    return Row(
      children: [
        Checkbox(
          value: isSelected,
          onChanged: onSelectionChanged,
          activeColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        _buildAvatar(context, initials),
        const SizedBox(width: 14),
        Expanded(
          child: Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  isHourly ? 'Hourly Worker' : 'Monthly Salary',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        if (isSelected)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'KES ${formatter.format(estimatedPay)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Text('Est.', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
        const SizedBox(width: 8),
        if (isSelected)
          Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.grey.shade400,
          ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context, String initials) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInputFields(BuildContext context, bool isHourly) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Days Worked toggle (only for monthly workers with partial periods)
        if (!isHourly && isPartialPeriod) ...[
          _buildDaysWorkedSection(context),
          const SizedBox(height: 16),
        ],

        Row(
          children: [
            Expanded(
              child: _buildInputField(
                context,
                label: isHourly ? 'Hours Worked' : 'Regular Hours',
                controller: hoursController,
                hint: isHourly ? '0' : '160',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInputField(
                context,
                label: 'Overtime Hours',
                controller: overtimeController,
                hint: '0',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                context,
                label: 'Bonuses',
                controller: bonusesController,
                hint: '0',
                icon: Icons.add_circle_outline,
                iconColor: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInputField(
                context,
                label: 'Other Deductions (Loan)',
                controller: deductionsController,
                hint: '0',
                icon: Icons.remove_circle_outline,
                iconColor: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildBaseRateInfo(context, isHourly),
      ],
    );
  }

  Widget _buildDaysWorkedSection(BuildContext context) {
    final daysWorked = int.tryParse(daysWorkedController.text) ?? totalDaysInPeriod;
    final isFullPeriod = daysWorked == totalDaysInPeriod;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFullPeriod ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFullPeriod ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                size: 16,
                color: isFullPeriod ? Colors.green.shade700 : Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Days Worked',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isFullPeriod ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRadioOption(
                  context,
                  label: 'Full Period',
                  sublabel: '$totalDaysInPeriod days',
                  isSelected: isFullPeriod,
                  onTap: () {
                    daysWorkedController.text = totalDaysInPeriod.toString();
                    onInputChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPartialOption(context, isFullPeriod),
              ),
            ],
          ),
          if (!isFullPeriod) ...[
            const SizedBox(height: 8),
            Text(
              'Prorated: ${formatter.format(worker.salaryGross)} × ($daysWorked/$totalDaysInPeriod)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRadioOption(
    BuildContext context, {
    required String label,
    required String sublabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: isSelected ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                Text(
                  sublabel,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartialOption(BuildContext context, bool isFullPeriod) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: !isFullPeriod ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: !isFullPeriod ? Colors.orange : Colors.grey.shade300,
          width: !isFullPeriod ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            !isFullPeriod ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: !isFullPeriod ? Colors.orange : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Partial',
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(
                  height: 24,
                  child: TextField(
                    controller: daysWorkedController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: '/ $totalDaysInPeriod',
                      suffixStyle: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => onInputChanged(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseRateInfo(BuildContext context, bool isHourly) {
    final daysWorked = int.tryParse(daysWorkedController.text) ?? totalDaysInPeriod;
    final isFullPeriod = daysWorked == totalDaysInPeriod || isHourly;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Base Rate', style: TextStyle(color: Colors.grey.shade700)),
              Text(
                isHourly
                    ? 'KES ${formatter.format(worker.hourlyRate ?? 0)}/hr'
                    : 'KES ${formatter.format(worker.salaryGross)}/mo',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (!isFullPeriod && !isHourly) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Prorated', style: TextStyle(color: Colors.orange.shade700)),
                Text(
                  'KES ${formatter.format(worker.salaryGross * daysWorked / totalDaysInPeriod)}',
                  style: TextStyle(fontWeight: FontWeight.w500, color: Colors.orange.shade700),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    Color? iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: icon != null 
                ? Icon(icon, size: 16, color: iconColor) 
                : null,
          ),
          onChanged: (_) => onInputChanged(),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'W';
    return name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase();
  }
}

