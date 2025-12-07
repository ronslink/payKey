import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class _TimeTrackingPageState extends ConsumerState<TimeTrackingPage>
    with SingleTickerProviderStateMixin {
  String? _selectedWorkerId;
  final _notesController = TextEditingController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _selectedWorkerId = widget.selectedWorkerId;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();

    // Fetch active entry if worker is pre-selected
    if (_selectedWorkerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(timeTrackingProvider.notifier).getActiveEntry(_selectedWorkerId!);
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workersState = ref.watch(workersProvider);
    final timeTrackingState = ref.watch(timeTrackingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.access_time_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Time Tracking',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF6B7280)),
            onPressed: () => context.push('/time-tracking/history'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Worker Selection - always show if no worker selected
            if (_selectedWorkerId == null)
              FadeTransition(
                opacity: _animationController,
                child: _buildWorkerSelection(workersState),
              ),

            if (_selectedWorkerId == null) const SizedBox(height: 24),

            // Current Status - show when worker is selected
            if (_selectedWorkerId != null)
              FadeTransition(
                opacity: _animationController,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOut,
                  )),
                  child: timeTrackingState.when(
                    data: (activeEntry) {
                      if (activeEntry == null) {
                        return _buildClockInCard();
                      } else {
                        return _buildClockedInCard(activeEntry);
                      }
                    },
                    loading: () => _buildLoadingCard(),
                    error: (error, _) => _buildErrorCard(error.toString()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerSelection(AsyncValue<dynamic> workersState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Worker',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Choose a worker to track time',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          workersState.when(
            data: (workers) {
              final workersList = workers as List<dynamic>;
              final activeWorkers = workersList
                  .where((w) => w.isActive == true)
                  .toList();

              if (activeWorkers.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFFF59E0B)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No active workers available',
                          style: TextStyle(color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                );
              }

return DropdownButtonFormField<String>(
                initialValue: _selectedWorkerId,
                decoration: InputDecoration(
                  hintText: 'Choose a worker',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  prefixIcon: const Icon(Icons.person),
                ),
                items: activeWorkers.map<DropdownMenuItem<String>>((worker) {
                  return DropdownMenuItem<String>(
                    value: worker.id as String,
                    child: Text(worker.name as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedWorkerId = value);
                  if (value != null) {
                    ref.read(timeTrackingProvider.notifier).getActiveEntry(value);
                  }
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
              ),
            ),
            error: (error, _) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error loading workers: ${error.toString()}',
                      style: const TextStyle(color: Color(0xFF991B1B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockInCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withValues(alpha: 0.1),
                  const Color(0xFF059669).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.login_outlined,
              size: 64,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ready to Clock In',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Worker is not currently clocked in',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Add any notes about this shift...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              prefixIcon: const Icon(Icons.note_outlined),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleClockIn,
              icon: const Icon(Icons.login),
              label: const Text('Clock In'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleClockIn() async {
    if (_selectedWorkerId == null) return;

    await ref.read(timeTrackingProvider.notifier).clockIn(
          _selectedWorkerId!,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
    _notesController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Clocked in successfully'),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildClockedInCard(TimeEntry entry) {
    final clockInTime = DateTime.parse(entry.clockInTime);
    final now = DateTime.now();
    final duration = now.difference(clockInTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.1),
            const Color(0xFF059669).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.timer_outlined,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Currently Clocked In',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.schedule, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(
                'Since ${clockInTime.hour.toString().padLeft(2, '0')}:${clockInTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Time Elapsed',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${hours}h ${minutes}m',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          if (entry.notes != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.note_outlined,
                    size: 20,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clock In Notes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.notes!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Clock Out Notes (optional)',
              hintText: 'Add any notes about this shift...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.note_outlined),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleClockOut(entry),
              icon: const Icon(Icons.logout),
              label: const Text('Clock Out'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleClockOut(TimeEntry entry) async {
    await ref.read(timeTrackingProvider.notifier).clockOut(
          entry.id,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
    _notesController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Clocked out successfully'),
            ],
          ),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        children: [
          SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading time tracking data...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.error_outline,
              size: 40,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load time tracking',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _handleRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleRetry() {
    if (_selectedWorkerId != null) {
      ref.read(timeTrackingProvider.notifier).getActiveEntry(_selectedWorkerId!);
    }
  }
}