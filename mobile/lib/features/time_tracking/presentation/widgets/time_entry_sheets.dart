import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/time_entry_model.dart';
import '../../data/repositories/time_tracking_repository.dart';

/// Sheets for the employer's side of time tracking.
///
/// Employers do not clock anybody in — the employee's own device does that — so
/// the employer's tools are recording hours they know about, correcting an
/// entry, and deciding whether hours reach payroll.

/// Ask for a date and a time, returning the combined instant.
Future<DateTime?> pickDateTime(
  BuildContext context, {
  required DateTime initial,
  required String helpText,
}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(initial.year - 2),
    lastDate: DateTime(initial.year + 2, 12, 31),
    helpText: helpText,
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

/// Record hours for a worker. Returns true when something was saved.
Future<bool> showRecordTimeSheet(
  BuildContext context,
  WidgetRef ref, {
  required String workerId,
  required String workerName,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RecordTimeSheet(
      ref: ref,
      workerId: workerId,
      workerName: workerName,
    ),
  );
  return saved ?? false;
}

/// Correct an existing entry. Returns true when something was saved.
Future<bool> showCorrectTimeSheet(
  BuildContext context,
  WidgetRef ref, {
  required TimeEntryModel entry,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CorrectTimeSheet(ref: ref, entry: entry),
  );
  return saved ?? false;
}

/// Review the hours that still need a payroll decision for a period.
/// Returns true when a decision was saved.
Future<bool> showPayrollReviewSheet(
  BuildContext context,
  WidgetRef ref, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PayrollReviewSheet(
      ref: ref,
      startDate: startDate,
      endDate: endDate,
    ),
  );
  return saved ?? false;
}

// ============================================================================
// Record time
// ============================================================================

class _RecordTimeSheet extends StatefulWidget {
  final WidgetRef ref;
  final String workerId;
  final String workerName;

  const _RecordTimeSheet({
    required this.ref,
    required this.workerId,
    required this.workerName,
  });

  @override
  State<_RecordTimeSheet> createState() => _RecordTimeSheetState();
}

class _RecordTimeSheetState extends State<_RecordTimeSheet> {
  late DateTime _clockIn;
  late DateTime _clockOut;
  final _breakController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default to a shift ending a moment ago, which is the usual correction.
    _clockOut = DateTime(now.year, now.month, now.day, now.hour, now.minute)
        .subtract(const Duration(minutes: 1));
    _clockIn = _clockOut.subtract(const Duration(hours: 8));
  }

  @override
  void dispose() {
    _breakController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _hours {
    final breakMinutes = int.tryParse(_breakController.text.trim()) ?? 0;
    final minutes =
        _clockOut.difference(_clockIn).inMinutes - breakMinutes.clamp(0, 100000);
    return (minutes / 60).clamp(0, 1000);
  }

  Future<void> _save() async {
    if (!_clockOut.isAfter(_clockIn)) {
      _message('The end of the shift must be after the start.');
      return;
    }
    if (_hours <= 0) {
      _message('The break is longer than the shift.');
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.ref.read(timeTrackingRepositoryProvider).createEntry(
            workerId: widget.workerId,
            clockIn: _clockIn,
            clockOut: _clockOut,
            breakMinutes: int.tryParse(_breakController.text.trim()),
            notes: _notesController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on TimeTrackingException catch (e) {
      _message(e.message);
    } catch (e) {
      _message('Could not record the time: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Record time for ${widget.workerName}',
      subtitle:
          'These hours wait for your approval before payroll counts them.',
      children: [
        _DateTimeRow(
          label: 'Shift start',
          value: _clockIn,
          onPick: () async {
            final picked = await pickDateTime(
              context,
              initial: _clockIn,
              helpText: 'Shift start date',
            );
            if (picked != null) setState(() => _clockIn = picked);
          },
        ),
        _DateTimeRow(
          label: 'Shift end',
          value: _clockOut,
          onPick: () async {
            final picked = await pickDateTime(
              context,
              initial: _clockOut,
              helpText: 'Shift end date',
            );
            if (picked != null) setState(() => _clockOut = picked);
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _breakController,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Unpaid break (minutes)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            hintText: 'e.g. covered the late shift',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _HoursSummary(hours: _hours),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Record time'),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Correct an entry
// ============================================================================

class _CorrectTimeSheet extends StatefulWidget {
  final WidgetRef ref;
  final TimeEntryModel entry;

  const _CorrectTimeSheet({required this.ref, required this.entry});

  @override
  State<_CorrectTimeSheet> createState() => _CorrectTimeSheetState();
}

class _CorrectTimeSheetState extends State<_CorrectTimeSheet> {
  late DateTime _clockIn;
  DateTime? _clockOut;
  late final TextEditingController _breakController;
  final _reasonController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _clockIn = widget.entry.clockIn.toLocal();
    _clockOut = widget.entry.clockOut?.toLocal();
    _breakController =
        TextEditingController(text: widget.entry.breakMinutes.toString());
  }

  @override
  void dispose() {
    _breakController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  double get _hours {
    final out = _clockOut;
    if (out == null) return 0;
    final breakMinutes = int.tryParse(_breakController.text.trim()) ?? 0;
    final minutes = out.difference(_clockIn).inMinutes - breakMinutes.clamp(0, 100000);
    return (minutes / 60).clamp(0, 1000);
  }

  Future<void> _save() async {
    if (_reasonController.text.trim().isEmpty) {
      _message('Say why you are changing this entry.');
      return;
    }
    if (_clockOut != null && !_clockOut!.isAfter(_clockIn)) {
      _message('The end of the shift must be after the start.');
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.ref.read(timeTrackingRepositoryProvider).correctEntry(
            widget.entry.id,
            clockIn: _clockIn,
            clockOut: _clockOut,
            breakMinutes: int.tryParse(_breakController.text.trim()),
            reason: _reasonController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on TimeTrackingException catch (e) {
      _message(e.message);
    } catch (e) {
      _message('Could not save the correction: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Correct this entry',
      subtitle:
          'Saving a correction returns the hours to pending, so payroll asks you about them again.',
      children: [
        _DateTimeRow(
          label: 'Shift start',
          value: _clockIn,
          onPick: () async {
            final picked = await pickDateTime(
              context,
              initial: _clockIn,
              helpText: 'Shift start date',
            );
            if (picked != null) setState(() => _clockIn = picked);
          },
        ),
        _DateTimeRow(
          label: 'Shift end',
          value: _clockOut,
          onPick: () async {
            final picked = await pickDateTime(
              context,
              initial: _clockOut ?? DateTime.now(),
              helpText: 'Shift end date',
            );
            if (picked != null) setState(() => _clockOut = picked);
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _breakController,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Unpaid break (minutes)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reasonController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Reason for the change',
            hintText: 'Kept with the entry as an audit trail',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _HoursSummary(hours: _hours),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save correction'),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Payroll review
// ============================================================================

class _PayrollReviewSheet extends StatefulWidget {
  final WidgetRef ref;
  final DateTime startDate;
  final DateTime endDate;

  const _PayrollReviewSheet({
    required this.ref,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<_PayrollReviewSheet> createState() => _PayrollReviewSheetState();
}

class _PayrollReviewSheetState extends State<_PayrollReviewSheet> {
  PayrollReview? _review;
  bool _loading = true;
  bool _saving = false;
  bool _changed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final review =
          await widget.ref.read(timeTrackingRepositoryProvider).getPayrollReview(
                startDate: widget.startDate,
                endDate: widget.endDate,
              );
      if (mounted) setState(() => _review = review);
    } on TimeTrackingException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load the review: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(List<String> entryIds, bool include) async {
    if (entryIds.isEmpty) return;

    setState(() => _saving = true);
    try {
      await widget.ref
          .read(timeTrackingRepositoryProvider)
          .decidePayroll(entryIds: entryIds, include: include);
      _changed = true;
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              include
                  ? '${entryIds.length} entr${entryIds.length == 1 ? 'y' : 'ies'} will be paid.'
                  : '${entryIds.length} entr${entryIds.length == 1 ? 'y' : 'ies'} excluded from pay.',
            ),
          ),
        );
      }
    } on TimeTrackingException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = _review;
    final pending = review?.allPendingEntries ?? const <PayrollReviewEntry>[];

    return _SheetFrame(
      title: 'Hours awaiting your decision',
      subtitle: pending.isEmpty
          ? 'Nothing is waiting. Hours entered by hand or auto-closed stay out of pay until you include them.'
          : '${pending.length} entr${pending.length == 1 ? 'y' : 'ies'} · '
              '${(review?.pendingHours ?? 0).toStringAsFixed(1)}h are not being paid yet.',
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red))
        else if (review != null) ...[
          if (pending.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving
                    ? null
                    : () => _decide(
                          pending.map((entry) => entry.id).toList(),
                          true,
                        ),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Include all of these hours'),
              ),
            ),
          const SizedBox(height: 16),
          for (final worker in review.workers)
            if (worker.pendingEntries.isNotEmpty)
              _PendingWorkerCard(
                worker: worker,
                busy: _saving,
                onDecide: _decide,
              ),
          const SizedBox(height: 8),
          _ReviewTotals(review: review),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(_changed),
              child: const Text('Done'),
            ),
          ),
        ],
      ],
    );
  }
}

class _PendingWorkerCard extends StatelessWidget {
  final PayrollReviewWorker worker;
  final bool busy;
  final Future<void> Function(List<String> entryIds, bool include) onDecide;

  const _PendingWorkerCard({
    required this.worker,
    required this.busy,
    required this.onDecide,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    worker.workerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${worker.pendingHours.toStringAsFixed(1)}h to decide',
                  style: TextStyle(color: Colors.orange.shade800),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Payable now ${worker.includedHours.toStringAsFixed(1)}h '
              '(${worker.clockedHours.toStringAsFixed(1)}h clocked)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const Divider(height: 20),
            for (final entry in worker.pendingEntries)
              _PendingEntryRow(
                entry: entry,
                busy: busy,
                onDecide: (include) => onDecide([entry.id], include),
              ),
          ],
        ),
      ),
    );
  }
}

class _PendingEntryRow extends StatelessWidget {
  final PayrollReviewEntry entry;
  final bool busy;
  final void Function(bool include) onDecide;

  const _PendingEntryRow({
    required this.entry,
    required this.busy,
    required this.onDecide,
  });

  @override
  Widget build(BuildContext context) {
    final localIn = entry.clockIn.toLocal();
    final localOut = entry.clockOut?.toLocal();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormat('EEE d MMM').format(localIn)} · '
                  '${DateFormat('HH:mm').format(localIn)}'
                  '${localOut == null ? '' : ' – ${DateFormat('HH:mm').format(localOut)}'}'
                  ' · ${entry.totalHours.toStringAsFixed(1)}h',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(entry.reasonLabel, style: const TextStyle(fontSize: 11.5)),
                if (entry.notes != null && entry.notes!.isNotEmpty)
                  Text(
                    entry.notes!,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Include in pay',
            onPressed: busy ? null : () => onDecide(true),
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
          ),
          IconButton(
            tooltip: 'Exclude from pay',
            onPressed: busy ? null : () => onDecide(false),
            icon: const Icon(Icons.block, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

class _ReviewTotals extends StatelessWidget {
  final PayrollReview review;

  const _ReviewTotals({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Will be paid: ${review.includedHours.toStringAsFixed(1)}h',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            'Clocked ${review.clockedHours.toStringAsFixed(1)}h · '
            'entered and included ${review.includedEnteredHours.toStringAsFixed(1)}h · '
            'pending ${review.pendingHours.toStringAsFixed(1)}h · '
            'excluded ${review.excludedHours.toStringAsFixed(1)}h',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Shared pieces
// ============================================================================

class _SheetFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SheetFrame({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  const _DateTimeRow({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onPick,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.edit_calendar),
          ),
          child: Text(
            value == null
                ? 'Not set'
                : DateFormat('EEE d MMM yyyy · HH:mm').format(value!),
          ),
        ),
      ),
    );
  }
}

class _HoursSummary extends StatelessWidget {
  final double hours;

  const _HoursSummary({required this.hours});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Total for this entry: ${hours.toStringAsFixed(2)}h',
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}
