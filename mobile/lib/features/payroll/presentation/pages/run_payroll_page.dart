import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../workers/presentation/providers/workers_provider.dart';
import '../providers/pay_period_provider.dart';
import '../../data/models/pay_period_model.dart';
import 'payroll_review_page.dart';

// Simple provider for selected workers
final selectedWorkersProvider = StateProvider<Set<String>>((ref) => {});

class RunPayrollPage extends ConsumerStatefulWidget {
  final String? payPeriodId;

  const RunPayrollPage({super.key, this.payPeriodId});

  @override
  ConsumerState<RunPayrollPage> createState() => _RunPayrollPageState();
}

class _RunPayrollPageState extends ConsumerState<RunPayrollPage> {
  PayPeriod? _payPeriod;
  bool _isCreatingPayPeriod = false;

  // Form controllers for pay period creation
  final _nameController = TextEditingController();
  PayPeriodFrequency? _selectedFrequency;
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(workersProvider.notifier).fetchWorkers();
      if (widget.payPeriodId != null) {
        _loadPayPeriod();
      } else {
        setState(() {
          _isCreatingPayPeriod = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _loadPayPeriod() async {
    try {
      final repository = ref.read(payPeriodRepositoryProvider);
      final period = await repository.getPayPeriodById(widget.payPeriodId!);
      if (mounted) {
        setState(() {
          _payPeriod = period;
          _isCreatingPayPeriod = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load pay period: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createPayPeriod() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final repository = ref.read(payPeriodRepositoryProvider);
      final newPeriod = await repository.createPayPeriod(CreatePayPeriodRequest(
        name: _nameController.text.trim(),
        startDate: DateTime.parse(_startDateController.text.trim()),
        endDate: DateTime.parse(_endDateController.text.trim()),
        frequency: _selectedFrequency!,
      ));

      if (mounted) {
        setState(() {
          _payPeriod = newPeriod;
          _isCreatingPayPeriod = false;
          _nameController.clear();
          _startDateController.clear();
          _endDateController.clear();
          _selectedFrequency = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pay period created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create pay period: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Payroll'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Trigger refresh for providers
              ref.invalidate(workersProvider);
              ref.invalidate(payPeriodsProvider);
            },
          ),
        ],
      ),
      body: _isCreatingPayPeriod ? _buildPayPeriodCreationForm() : _buildPayrollRunInterface(),
    );
  }

  Widget _buildPayPeriodCreationForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Pay Period',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Pay Period Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a pay period name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PayPeriodFrequency>(
              initialValue: _selectedFrequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: PayPeriodFrequency.values.map((frequency) {
                return DropdownMenuItem<PayPeriodFrequency>(
                  value: frequency,
                  child: Text(frequency.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFrequency = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a frequency';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _startDateController,
              decoration: const InputDecoration(
                labelText: 'Start Date (YYYY-MM-DD)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a start date';
                }
                try {
                  DateTime.parse(value.trim());
                } catch (_) {
                  return 'Invalid date format';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endDateController,
              decoration: const InputDecoration(
                labelText: 'End Date (YYYY-MM-DD)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an end date';
                }
                try {
                  DateTime.parse(value.trim());
                } catch (_) {
                  return 'Invalid date format';
                }
                if (_startDateController.text.isNotEmpty) {
                  try {
                    final start = DateTime.parse(_startDateController.text.trim());
                    final end = DateTime.parse(value.trim());
                    if (!start.isBefore(end)) {
                      return 'Start date must be before end date';
                    }
                  } catch (_) {}
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createPayPeriod,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Create Pay Period'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayrollRunInterface() {
    final workersState = ref.watch(workersProvider);
    final selectedWorkers = ref.watch(selectedWorkersProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Run Payroll',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text(
            'Pay Period: ${_payPeriod?.name ?? 'Not selected'}',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Workers:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  workersState.whenData((workers) {
                    final allIds = workers.where((w) => w.isActive).map((w) => w.id).toSet();
                    if (selectedWorkers.length == allIds.length) {
                      ref.read(selectedWorkersProvider.notifier).state = {};
                    } else {
                      ref.read(selectedWorkersProvider.notifier).state = allIds;
                    }
                  });
                },
                child: Text(
                  selectedWorkers.isNotEmpty ? 'Deselect All' : 'Select All',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: workersState.when(
              data: (workers) {
                final activeWorkers = workers.where((w) => w.isActive).toList();
                
                if (activeWorkers.isEmpty) {
                  return const Center(
                    child: Text('No active workers found'),
                  );
                }

                return ListView.builder(
                  itemCount: activeWorkers.length,
                  itemBuilder: (context, index) {
                    final worker = activeWorkers[index];
                    final isSelected = selectedWorkers.contains(worker.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          final currentSelected = ref.read(selectedWorkersProvider);
                          if (value == true) {
                            ref.read(selectedWorkersProvider.notifier).state = {...currentSelected, worker.id};
                          } else {
                            ref.read(selectedWorkersProvider.notifier).state = {...currentSelected}..remove(worker.id);
                          }
                        },
                        title: Text(worker.name),
                        subtitle: Text(worker.jobTitle ?? 'No Job Title'),
                        secondary: CircleAvatar(
                          child: Text(worker.name[0].toUpperCase()),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedWorkers.isEmpty ? null : () {
                _calculatePayroll(selectedWorkers);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Calculate Payroll'),
            ),
          ),
        ],
      ),
    );
  }

  void _calculatePayroll(Set<String> workerIds) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calculating payroll for ${workerIds.length} workers...'),
      ),
    );
    
Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _payPeriod != null) {
         Navigator.of(context).push(
           MaterialPageRoute(
             builder: (context) => PayrollReviewPage(payPeriodId: _payPeriod!.id),
           ),
         );
      }
    });
  }
}
