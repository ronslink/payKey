import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/payroll_repository.dart';

/// A dialog that shows real-time payroll processing progress.
/// 
/// Polls the backend for job status updates and displays:
/// - Progress indicator
/// - Current status message
/// - Worker count
/// - Success/failure result
class PayrollProcessingDialog extends ConsumerStatefulWidget {
  final String jobId;
  final int workerCount;
  final VoidCallback onComplete;
  final VoidCallback onError;

  const PayrollProcessingDialog({
    super.key,
    required this.jobId,
    required this.workerCount,
    required this.onComplete,
    required this.onError,
  });

  static Future<void> show({
    required BuildContext context,
    required String jobId,
    required int workerCount,
    required VoidCallback onComplete,
    required VoidCallback onError,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PayrollProcessingDialog(
        jobId: jobId,
        workerCount: workerCount,
        onComplete: () {
          Navigator.of(dialogContext).pop();
          onComplete();
        },
        onError: () {
          Navigator.of(dialogContext).pop();
          onError();
        },
      ),
    );
  }

  @override
  ConsumerState<PayrollProcessingDialog> createState() =>
      _PayrollProcessingDialogState();
}

class _PayrollProcessingDialogState
    extends ConsumerState<PayrollProcessingDialog>
    with SingleTickerProviderStateMixin {
  Timer? _pollingTimer;
  String _statusMessage = 'Initializing...';
  int _progress = 0;
  bool _isComplete = false;
  bool _hasError = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Design constants matching app theme
  static const _successColor = Color(0xFF10B981);
  static const _primaryColor = Color(0xFF1B5E20);
  static const _errorColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startPolling() {
    // Poll every 2 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkJobStatus();
    });
    // Also check immediately
    _checkJobStatus();
  }

  Future<void> _checkJobStatus() async {
    if (_isComplete || _hasError) return;

    try {
      final repo = ref.read(payrollRepositoryProvider);
      final status = await repo.getJobStatus(widget.jobId);

      if (!mounted) return;

      setState(() {
        _progress = status.progress;
        _statusMessage = status.statusMessage;
      });

      if (status.isCompleted) {
        _pollingTimer?.cancel();
        _pulseController.stop();
        setState(() {
          _isComplete = true;
          _statusMessage = 'Payroll completed successfully!';
          _progress = 100;
        });
        // Wait a moment to show completion, then close
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          widget.onComplete();
        }
      } else if (status.isFailed) {
        _pollingTimer?.cancel();
        _pulseController.stop();
        setState(() {
          _hasError = true;
          _statusMessage = status.failedReason ?? 'Processing failed';
        });
      }
    } catch (e) {
      // Don't stop polling on transient errors
      debugPrint('Job status check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button during processing
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            _buildStatusIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _hasError
                    ? 'Processing Failed'
                    : _isComplete
                        ? 'Payroll Complete'
                        : 'Processing Payroll',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status message
            Text(
              _statusMessage,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            // Progress section
            if (!_hasError) ...[
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _isComplete ? 1.0 : (_progress > 0 ? _progress / 100 : null),
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isComplete ? _successColor : _primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Progress details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.workerCount} employee${widget.workerCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _isComplete ? 'Done!' : '$_progress%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isComplete ? _successColor : _primaryColor,
                    ),
                  ),
                ],
              ),
            ],

            // Completion checklist
            if (_isComplete) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _buildChecklistItem('Payments initiated', true),
              _buildChecklistItem('Payslips generated', true),
              _buildChecklistItem('Tax returns filed', true),
              _buildChecklistItem('Records finalized', true),
            ],

            // Error details
            if (_hasError) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _errorColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: _errorColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please try again or contact support if the issue persists.',
                        style: TextStyle(
                          color: _errorColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: _hasError
            ? [
                TextButton(
                  onPressed: widget.onError,
                  child: const Text('Close'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _statusMessage = 'Retrying...';
                      _progress = 0;
                    });
                    _startPolling();
                  },
                  child: const Text('Retry'),
                ),
              ]
            : _isComplete
                ? [
                    FilledButton(
                      onPressed: widget.onComplete,
                      child: const Text('Done'),
                    ),
                  ]
                : null, // No actions while processing
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _errorColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.error_outline, color: _errorColor, size: 24),
      );
    }

    if (_isComplete) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _successColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_circle, color: _successColor, size: 24),
      );
    }

    // Processing animation
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: _pulseAnimation.value,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String text, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: completed ? _successColor : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: completed ? Colors.black87 : Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the payroll processing dialog and returns when complete or failed.
/// 
/// Returns true if processing completed successfully, false otherwise.
Future<bool> showPayrollProcessingDialog({
  required BuildContext context,
  required String jobId,
  required int workerCount,
}) async {
  final completer = Completer<bool>();

  await PayrollProcessingDialog.show(
    context: context,
    jobId: jobId,
    workerCount: workerCount,
    onComplete: () => completer.complete(true),
    onError: () => completer.complete(false),
  );

  return completer.future;
}
