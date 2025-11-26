import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../workers/presentation/providers/workers_provider.dart';
import '../providers/pay_period_provider.dart';
import '../../data/models/pay_period_model.dart';

// Simple provider for selected workers
final selectedWorkersProvider = StateProvider<Set<String>>((ref) => {});

class RunPayrollPage extends ConsumerStatefulWidget {
  final String? payPeriodId;

  const RunPayrollPage({super.key, this.payPeriodId});

  @override
  ConsumerState<RunPayrollPage> createState() => _RunPayrollPageState();
}

class _RunPayrollPageState extends ConsumerState<RunPayrollPage> {
  String? _selectedPropertyId;
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
        startDate: DateTime.now(),
        endDate: DateTime.now(),
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
    final workersState = ref.watch(workersProvider);
    final payPeriodsState = ref.watch(payPeriodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Payroll'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(workersProvider);
              ref.refresh(payPeriodsProvider);
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
          const Text(
            'Select Workers:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: 0, // TODO: Add worker list display
              itemBuilder: (context, index) {
                return ListTile(
                  title: const Text('Worker Name'),
                  trailing: Checkbox(
                    value: false, // TODO: Add worker selection logic
                    onChanged: (value) {},
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement payroll calculation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payroll calculation not implemented yet')),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Calculate Payroll'),
            ),
          ),
        ],
      ),
    );
  }
}
