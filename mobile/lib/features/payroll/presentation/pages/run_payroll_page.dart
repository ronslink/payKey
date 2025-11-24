import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../workers/presentation/providers/workers_provider.dart';
import '../providers/payroll_provider.dart';
import '../providers/pay_period_provider.dart';
import '../../../properties/presentation/providers/properties_provider.dart';

class RunPayrollPage extends ConsumerStatefulWidget {
  final String payPeriodId;

  const RunPayrollPage({super.key, required this.payPeriodId});

  @override
  ConsumerState<RunPayrollPage> createState() => _RunPayrollPageState();
}

class _RunPayrollPageState extends ConsumerState<RunPayrollPage> {
  String? _selectedPropertyId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(workersProvider.notifier).fetchWorkers();
      // Properties provider is FutureProvider, no need to manually fetch
    });
  }

  @override
  Widget build(BuildContext context) {
    final workersState = ref.watch(workersProvider);
    final selectedWorkers = ref.watch(selectedWorkersProvider);
    final propertiesState = ref.watch(propertiesProvider);
    final payPeriodsState = ref.watch(payPeriodsProvider);

    // Find the pay period
    final payPeriod = payPeriodsState.value?.firstWhere(
      (p) => p.id == widget.payPeriodId,
      orElse: () => throw Exception('Pay Period not found'),
    );

    if (payPeriod == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Run Payroll: ${payPeriod.name}'),
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
                  value: _selectedPropertyId,
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
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Workers List
          Expanded(
            child: workersState.when(
              data: (workers) {
                // Filter active workers and then by property
                final activeWorkers = workers.where((w) => w.isActive).toList();
                final filteredWorkers = _selectedPropertyId == null
                    ? activeWorkers
                    : activeWorkers.where((w) => w.propertyId == _selectedPropertyId).toList();

                if (filteredWorkers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _selectedPropertyId == null
                              ? 'No active workers'
                              : 'No workers in this property',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedWorkers.length} selected',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              final allFilteredSelected = filteredWorkers.every((w) => selectedWorkers.contains(w.id));
                              
                              if (allFilteredSelected) {
                                final newSet = Set<String>.from(selectedWorkers);
                                for (var w in filteredWorkers) {
                                  newSet.remove(w.id);
                                }
                                ref.read(selectedWorkersProvider.notifier).state = newSet;
                              } else {
                                final newSet = Set<String>.from(selectedWorkers);
                                for (var w in filteredWorkers) {
                                  newSet.add(w.id);
                                }
                                ref.read(selectedWorkersProvider.notifier).state = newSet;
                              }
                            },
                            child: Text(
                              filteredWorkers.every((w) => selectedWorkers.contains(w.id))
                                  ? 'Deselect All'
                                  : 'Select All',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredWorkers.length,
                        itemBuilder: (context, index) {
                          final worker = filteredWorkers[index];
                          final isSelected = selectedWorkers.contains(worker.id);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              final newSet = Set<String>.from(selectedWorkers);
                              if (value == true) {
                                newSet.add(worker.id);
                              } else {
                                newSet.remove(worker.id);
                              }
                              ref.read(selectedWorkersProvider.notifier).state = newSet;
                            },
                            title: Text(worker.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(worker.phoneNumber),
                                Text(
                                  'Gross Salary: KES ${worker.salaryGross.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            secondary: CircleAvatar(
                              child: Text(worker.name[0].toUpperCase()),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: ${error.toString()}'),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: selectedWorkers.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(payrollProvider.notifier).calculatePayroll(
                          selectedWorkers.toList(),
                          startDate: payPeriod.startDate,
                          endDate: payPeriod.endDate,
                        );
                    if (context.mounted) {
                      context.push('/payroll/review/${widget.payPeriodId}');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('Calculate Payroll'),
                ),
              ),
            ),
    );
  }
}
