import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/time_tracking_provider.dart';
import '../../data/models/time_tracking_model.dart';

import '../../../properties/presentation/providers/properties_provider.dart';

class TimeTrackingHistoryPage extends ConsumerStatefulWidget {
  const TimeTrackingHistoryPage({super.key});

  @override
  ConsumerState<TimeTrackingHistoryPage> createState() => _TimeTrackingHistoryPageState();
}

class _TimeTrackingHistoryPageState extends ConsumerState<TimeTrackingHistoryPage> {
  String? _selectedPropertyId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(timeEntriesProvider.notifier).fetchTimeEntries();
      // Properties provider is FutureProvider, no need to manually fetch
    });
  }

  @override
  Widget build(BuildContext context) {
    final entriesState = ref.watch(timeEntriesProvider);
    final propertiesState = ref.watch(propertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Tracking History'),
      ),
      body: Column(
        children: [
          // Property Filter
          propertiesState.when(
            data: (properties) {
              if (properties.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedPropertyId,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Property',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.filter_list),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Properties'),
                    ),
                    ...properties.map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedPropertyId = value);
                  },
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Entries List
          Expanded(
            child: entriesState.when(
              data: (entries) {
                // Filter entries based on selected property
                final filteredEntries = _selectedPropertyId == null
                    ? entries
                    : entries.where((e) => e.propertyId == _selectedPropertyId).toList();

                if (filteredEntries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _selectedPropertyId == null
                              ? 'No time entries yet'
                              : 'No entries for this property',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = filteredEntries[index];
                    return _TimeEntryCard(entry: entry);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${error.toString()}'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeEntryCard extends StatelessWidget {
  final TimeEntry entry;

  const _TimeEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final clockInTime = DateTime.parse(entry.clockInTime);
    final clockOutTime = entry.clockOutTime != null
        ? DateTime.parse(entry.clockOutTime!)
        : null;
    final isCompleted = entry.status == TimeEntryStatus.completed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.access_time,
                  color: isCompleted ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCompleted ? 'Completed' : 'In Progress',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                if (entry.totalHours != null)
                  Chip(
                    label: Text('${entry.totalHours!.toStringAsFixed(2)}h'),
                    backgroundColor: Colors.blue.shade50,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.login, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Clock In: ${clockInTime.hour}:${clockInTime.minute.toString().padLeft(2, '0')} - ${clockInTime.day}/${clockInTime.month}/${clockInTime.year}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            if (clockOutTime != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.logout, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Clock Out: ${clockOutTime.hour}:${clockOutTime.minute.toString().padLeft(2, '0')} - ${clockOutTime.day}/${clockOutTime.month}/${clockOutTime.year}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
            if (entry.notes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.notes!)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
