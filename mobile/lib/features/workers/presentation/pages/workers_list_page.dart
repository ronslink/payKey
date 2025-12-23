import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/workers_provider.dart';
import '../../data/models/worker_model.dart';

// =============================================================================
// CONSTANTS
// =============================================================================

abstract class _AppColors {
  static const background = Color(0xFFF9FAFB);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const primary = Color(0xFF3B82F6);
  static const primaryDark = Color(0xFF1E40AF);
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEF2F2);
  static const infoLight = Color(0xFFEFF6FF);
  static const divider = Color(0xFFD1D5DB);
  static const muted = Color(0xFFF3F4F6);
}

abstract class _Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

// =============================================================================
// MAIN PAGE
// =============================================================================

class WorkersListPage extends ConsumerStatefulWidget {
  const WorkersListPage({super.key});

  @override
  ConsumerState<WorkersListPage> createState() => _WorkersListPageState();
}

class _WorkersListPageState extends ConsumerState<WorkersListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workersProvider.notifier).loadWorkers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Filtering
  // ---------------------------------------------------------------------------

  List<WorkerModel> _filterWorkers(List<WorkerModel> workers) {
    if (_searchQuery.isEmpty) return workers;

    final query = _searchQuery.toLowerCase();
    return workers.where((worker) {
      return worker.name.toLowerCase().contains(query) ||
          worker.phoneNumber.toLowerCase().contains(query);
    }).toList();
  }

  void _clearSearch() {
    setState(() => _searchQuery = '');
    _searchController.clear();
  }

  void _updateSearch(String query) {
    setState(() => _searchQuery = query);
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _refreshWorkers() async {
    await ref.read(workersProvider.notifier).loadWorkers();
  }

  void _navigateToAddWorker() => context.go('/workers/add');

  void _navigateToWorkerDetails(String workerId) {
    context.go('/workers/$workerId');
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _SearchDialog(
        controller: _searchController,
        onChanged: _updateSearch,
        onClear: () {
          _clearSearch();
          Navigator.of(context).pop();
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final workersState = ref.watch(workersProvider);

    return Scaffold(
      backgroundColor: _AppColors.background,
      appBar: _buildAppBar(),
      body: workersState.when(
        data: (allWorkers) => _buildDataState(allWorkers),
        loading: () => const _LoadingState(),
        error: (error, _) => _ErrorState(
          error: error,
          onRetry: _refreshWorkers,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddWorker,
        backgroundColor: _AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _AppColors.surface,
      foregroundColor: _AppColors.textPrimary,
      elevation: 0,
      title: const Text(
        'Workers',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _AppColors.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: _AppColors.textSecondary),
          onPressed: _refreshWorkers,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.search, color: _AppColors.textSecondary),
          onPressed: _showSearchDialog,
          tooltip: 'Search',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: _AppColors.textSecondary),
          onSelected: (value) {
            if (value == 'archived') {
              context.push('/workers/archived');
            } else if (value == 'import') {
              context.push('/workers/import');
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'import',
              child: Row(
                children: [
                  Icon(Icons.upload_file, color: _AppColors.primary),
                  SizedBox(width: 8),
                  Text('Import Workers'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'archived',
              child: Row(
                children: [
                  Icon(Icons.archive_outlined, color: _AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text('Archived Workers'),
                ],
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.add, color: _AppColors.primary),
          onPressed: _navigateToAddWorker,
          tooltip: 'Add Worker',
        ),
      ],
    );
  }

  Widget _buildDataState(List<WorkerModel> allWorkers) {
    if (allWorkers.isEmpty) {
      return _EmptyState(onAddWorker: _navigateToAddWorker);
    }

    final filteredWorkers = _filterWorkers(allWorkers);

    if (filteredWorkers.isEmpty) {
      return _NoSearchResultsState(onClearSearch: _clearSearch);
    }

    return RefreshIndicator(
      onRefresh: _refreshWorkers,
      child: ListView.builder(
        padding: const EdgeInsets.all(_Spacing.lg),
        itemCount: filteredWorkers.length,
        itemBuilder: (context, index) {
          final worker = filteredWorkers[index];
          return _WorkerCard(
            worker: worker,
            onTap: () => _navigateToWorkerDetails(worker.id),
          );
        },
      ),
    );
  }
}

// =============================================================================
// STATE WIDGETS
// =============================================================================

// -----------------------------------------------------------------------------
// Loading State
// -----------------------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_AppColors.primary),
            ),
          ),
          SizedBox(height: _Spacing.lg),
          Text(
            'Loading workers...',
            style: TextStyle(
              fontSize: 16,
              color: _AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Error State
// -----------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _StateIcon(
              icon: Icons.error_outline,
              backgroundColor: _AppColors.errorLight,
              iconColor: _AppColors.error,
            ),
            const SizedBox(height: _Spacing.lg),
            const Text(
              'Failed to load workers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: _Spacing.sm),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: _Spacing.xl),
            _PrimaryButton(
              label: 'Try Again',
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Empty State
// -----------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddWorker;

  const _EmptyState({required this.onAddWorker});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _StateIcon(
              icon: Icons.people_outline,
              backgroundColor: _AppColors.muted,
              iconColor: _AppColors.textMuted,
              size: 120,
              iconSize: 60,
            ),
            const SizedBox(height: _Spacing.xl),
            const Text(
              'No workers yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: _Spacing.sm),
            const Text(
              'Add your first worker to start managing\nyour domestic staff efficiently',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: _Spacing.xxl),
            _PrimaryButton(
              label: 'Add First Worker',
              icon: Icons.person_add,
              onPressed: onAddWorker,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// No Search Results State
// -----------------------------------------------------------------------------

class _NoSearchResultsState extends StatelessWidget {
  final VoidCallback onClearSearch;

  const _NoSearchResultsState({required this.onClearSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _StateIcon(
            icon: Icons.search,
            backgroundColor: _AppColors.infoLight,
            iconColor: _AppColors.primary,
          ),
          const SizedBox(height: _Spacing.lg),
          const Text(
            'No workers found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: _Spacing.sm),
          const Text(
            'Try adjusting your search terms',
            style: TextStyle(
              color: _AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: _Spacing.xl),
          _PrimaryButton(
            label: 'Clear Search',
            onPressed: onClearSearch,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// WORKER CARD
// =============================================================================

class _WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final VoidCallback onTap;

  const _WorkerCard({
    required this.worker,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: _Spacing.md),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(_Spacing.lg),
            child: Row(
              children: [
                _WorkerAvatar(name: worker.name),
                const SizedBox(width: _Spacing.lg),
                Expanded(child: _WorkerInfo(worker: worker)),
                _WorkerTrailing(isActive: worker.isActive),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Worker Card Components
// -----------------------------------------------------------------------------

class _WorkerAvatar extends StatelessWidget {
  final String name;

  const _WorkerAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_AppColors.primary, _AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _WorkerInfo extends StatelessWidget {
  final WorkerModel worker;

  const _WorkerInfo({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          worker.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: _Spacing.xs),
        _IconText(
          icon: Icons.phone,
          text: worker.phoneNumber,
          color: _AppColors.textSecondary,
        ),
        const SizedBox(height: _Spacing.xs + 2),
        _IconText(
          icon: Icons.attach_money,
          text: 'KES ${worker.salaryGross.toStringAsFixed(0)}',
          color: _AppColors.success,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}

class _WorkerTrailing extends StatelessWidget {
  final bool isActive;

  const _WorkerTrailing({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _StatusBadge(isActive: isActive),
        const SizedBox(height: _Spacing.sm),
        const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: _AppColors.divider,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _AppColors.success : _AppColors.error;
    final bgColor = isActive ? _AppColors.successLight : _AppColors.errorLight;
    final label = isActive ? 'Active' : 'Inactive';
    final icon = isActive ? Icons.check_circle : Icons.cancel;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _Spacing.sm,
        vertical: _Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: _Spacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// REUSABLE WIDGETS
// =============================================================================

// -----------------------------------------------------------------------------
// State Icon
// -----------------------------------------------------------------------------

class _StateIcon extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final double iconSize;

  const _StateIcon({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.size = 80,
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Primary Button
// -----------------------------------------------------------------------------

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style: _buttonStyle,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: _buttonStyle,
      child: Text(label),
    );
  }

  ButtonStyle get _buttonStyle => ElevatedButton.styleFrom(
        backgroundColor: _AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: _Spacing.xl,
          vertical: _Spacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );
}

// -----------------------------------------------------------------------------
// Icon Text Row
// -----------------------------------------------------------------------------

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final FontWeight fontWeight;

  const _IconText({
    required this.icon,
    required this.text,
    required this.color,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: _Spacing.xs),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: fontWeight,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// DIALOGS
// =============================================================================

class _SearchDialog extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onClose;

  const _SearchDialog({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text('Search Workers'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Enter name or phone number...',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) {
          onChanged(value);
          if (value.isEmpty) {
            onClose();
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: onClear,
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: onClose,
          child: const Text('Close'),
        ),
      ],
    );
  }
}