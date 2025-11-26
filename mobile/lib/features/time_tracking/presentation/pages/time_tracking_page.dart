import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../workers/presentation/providers/workers_provider.dart';
import '../providers/time_tracking_provider.dart';
import '../../data/models/time_tracking_model.dart';

class TimeTrackingPage extends ConsumerStatefulWidget {
  final String? selectedWorkerId;
  
  const TimeTrackingPage({
    super.key,
    this.selectedWorkerId,
  });

  @override
  ConsumerState<TimeTrackingPage> createState() => _TimeTrackingPageState();
}

class _TimeTrackingPageState extends ConsumerState<TimeTrackingPage> {
  String? _selectedWorkerId;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedWorkerId = widget.selectedWorkerId;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workersState = ref.watch(workersProvider);
    final timeTrackingState = ref.watch(timeTrackingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Worker Selection (only show if not provided from parent)
          if (_selectedWorkerId == null) ...[
            workersState.when(
              data: (workers) {
                final activeWorkers = workers.where((w) => w.isActive).toList();
                
                if (activeWorkers.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No active workers available'),
                    ),
                  );
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Worker',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedWorkerId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Choose a worker',
                          ),
                          items: activeWorkers.map((worker) {
                            return DropdownMenuItem(
                              value: worker.id,
                              child: Text(worker.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedWorkerId = value);
                            if (value != null) {
                              ref.read(timeTrackingProvider.notifier).getActiveEntry(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: ${error.toString()}'),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],

          // Current Status
          if (_selectedWorkerId != null)
            timeTrackingState.when(
              data: (activeEntry) {
                if (activeEntry == null) {
                  return _buildClockInCard();
                } else {
                  return _buildClockedInCard(activeEntry);
                }
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, _) => Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: ${error.toString()}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClockInCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.access_time,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ready to Clock In',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Worker is not currently clocked in',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                hintText: 'Add any notes...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_selectedWorkerId != null) {
                    await ref.read(timeTrackingProvider.notifier).clockIn(
                          _selectedWorkerId!,
                          notes: _notesController.text.isEmpty
                              ? null
                              : _notesController.text,
                        );
                    _notesController.clear();
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('Clock In'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockedInCard(TimeEntry entry) {
    final clockInTime = DateTime.parse(entry.clockInTime);
    final now = DateTime.now();
    final duration = now.difference(clockInTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.timer,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Currently Clocked In',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Since ${clockInTime.hour}:${clockInTime.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Time Elapsed',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${hours}h ${minutes}m',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            if (entry.notes != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.notes!)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Clock Out Notes (optional)',
                border: OutlineInputBorder(),
                hintText: 'Add any notes...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(timeTrackingProvider.notifier).clockOut(
                        entry.id,
                        notes: _notesController.text.isEmpty
                            ? null
                            : _notesController.text,
                      );
                  _notesController.clear();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Clock Out'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
