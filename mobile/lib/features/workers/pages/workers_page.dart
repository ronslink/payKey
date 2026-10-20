import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Domain imports
import '../data/models/worker_model.dart';
import '../presentation/providers/workers_provider.dart';
import '../../properties/presentation/providers/properties_provider.dart';
import '../../subscriptions/presentation/providers/feature_access_provider.dart';

// Local imports
import '../constants/workers_constants.dart';
import '../utils/worker_filter.dart';

import '../widgets/workers_widgets.dart';
import '../widgets/worker_card.dart';

/// Key for SharedPreferences to store property prompt dismissal
const String _kPropertyPromptDismissed = 'property_prompt_dismissed';

/// Workers page with search, filter, and compliance tracking
class WorkersPage extends ConsumerStatefulWidget {
  const WorkersPage({super.key});

  @override
  ConsumerState<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends ConsumerState<WorkersPage> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  WorkerFilterState _filterState = const WorkerFilterState();
  bool _propertyPromptDismissed = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadPropertyPromptPreference();
  }

  Future<void> _loadPropertyPromptPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _propertyPromptDismissed =
            prefs.getBool(_kPropertyPromptDismissed) ?? false;
      });
    }
  }

  Future<void> _dismissPropertyPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPropertyPromptDismissed, true);
    if (mounted) {
      setState(() {
        _propertyPromptDismissed = true;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(WorkersConstants.searchDebounce, () {
      if (mounted) {
        setState(() {
          _filterState = _filterState.copyWith(
            searchQuery: _searchController.text.trim().toLowerCase(),
          );
        });
      }
    });
  }

  void _updateStatusFilter(WorkerFilter filter) {
    setState(() {
      _filterState = _filterState.copyWith(statusFilter: filter);
    });
  }

  void _updatePropertyFilter(String? propertyId) {
    setState(() {
      _filterState = _filterState.copyWith(
        propertyId: propertyId,
        clearPropertyId: propertyId == null,
      );
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _filterState = _filterState.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workersProvider);

    return Scaffold(
      backgroundColor: WorkersTheme.backgroundColor(context),
      appBar: _buildAppBar(context),
      floatingActionButton: _buildFab(context),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsRow(workersAsync),
                WorkerSearchBar(
                  controller: _searchController,
                  query: _filterState.searchQuery,
                  onClear: () => _searchController.clear(),
                ),
                WorkerFilterChips(
                  selectedFilter: _filterState.statusFilter,
                  onFilterChanged: _updateStatusFilter,
                ),
                _buildPropertyFilter(),
              ],
            ),
          ),
          _buildWorkersList(workersAsync),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final titleFontSize = MediaQuery.textScalerOf(context).scale(20);
    final titleLines =
        MediaQuery.sizeOf(context).width < 380 && titleFontSize > 25 ? 3 : 2;
    // Check if user is PLATINUM tier
    final summaryAsync = ref.watch(subscriptionSummaryProvider);
    final isPlatinum = summaryAsync.when(
      data: (summary) => summary.tier.toUpperCase() == 'PLATINUM',
      loading: () => false,
      error: (_, __) => false,
    );

    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      toolbarHeight: titleFontSize > 20
          ? titleFontSize * 1.4 * titleLines + 8
          : kToolbarHeight,
      title: Text('My Workforce', maxLines: titleLines, softWrap: true),
      actions: [
        // Properties button for PLATINUM users
        if (isPlatinum)
          IconButton(
            icon: const Icon(Icons.home_work_outlined),
            tooltip: 'Manage Properties',
            onPressed: () => context.push('/properties'),
          ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.15),
                  const Color(0xFFEC4899).withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              ),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFFEC4899),
                  Color(0xFF8B5CF6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Icon(Icons.file_upload_outlined, size: 22),
            ),
          ),
          onPressed: () => context.push(WorkersConstants.importWorkersRoute),
          tooltip: 'Import Workers',
        ),
        IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: 'Help',
          onPressed: () => _showHelpSnackbar(context),
        ),
      ],
    );
  }

  void _showHelpSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manage your workers, their payroll and compliance'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.push(WorkersConstants.addWorkerRoute),
      child: const Icon(Icons.add),
    );
  }

  Widget _buildStatsRow(AsyncValue<List<WorkerModel>> workersAsync) {
    final stats = workersAsync.when(
      data: (workers) => WorkerStats.fromWorkers(workers),
      loading: () => const WorkerStats.empty(),
      error: (error, stackTrace) => const WorkerStats.empty(),
    );

    return WorkerStatsRow(stats: stats);
  }

  Widget _buildPropertyFilter() {
    // Only show property filter for PLATINUM tier users
    final summaryAsync = ref.watch(subscriptionSummaryProvider);
    final isPlatinum = summaryAsync.when(
      data: (summary) => summary.tier.toUpperCase() == 'PLATINUM',
      loading: () => false,
      error: (_, __) => false,
    );

    // Don't fetch or show properties for non-PLATINUM users
    if (!isPlatinum) {
      return const SizedBox.shrink();
    }

    final propertiesAsync = ref.watch(propertiesProvider);

    return propertiesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (properties) {
        // Show add property prompt if PLATINUM user has no properties AND hasn't dismissed
        if (properties.isEmpty && !_propertyPromptDismissed) {
          return _buildAddPropertyPrompt();
        }
        return PropertyFilterDropdown(
          selectedPropertyId: _filterState.propertyId,
          properties: properties,
          onChanged: _updatePropertyFilter,
        );
      },
    );
  }

  Widget _buildAddPropertyPrompt() {
    return PropertySetupPrompt(
      onShowInfo: _showPropertyInfoDialog,
      onAddProperty: () => context.push('/properties/add'),
      onDismiss: _dismissPropertyPrompt,
    );
  }

  void _showPropertyInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => PropertyInfoDialog(
        onMaybeLater: () => Navigator.of(dialogContext).pop(),
        onAddProperty: () {
          Navigator.of(dialogContext).pop();
          context.push('/properties/add');
        },
      ),
    );
  }

  Widget _buildWorkersList(AsyncValue<List<WorkerModel>> workersAsync) {
    return workersAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => SliverFillRemaining(
        hasScrollBody: false,
        child: WorkersErrorState(
          onRetry: () => ref.invalidate(workersProvider),
        ),
      ),
      data: (workers) => _buildFilteredList(workers),
    );
  }

  Widget _buildFilteredList(List<WorkerModel> workers) {
    final filtered = _applyFilters(workers);

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: WorkersEmptyState(
          hasFilters: _filterState.hasActiveFilters,
          hasSearchQuery: _filterState.searchQuery.isNotEmpty,
          onAddWorker: () => context.push(WorkersConstants.addWorkerRoute),
          onClearFilters: _clearFilters,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        WorkersTheme.pagePadding,
        0,
        WorkersTheme.pagePadding,
        100,
      ),
      sliver: SliverList.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final worker = filtered[index];
          return WorkerCard(
            data: WorkerCardData.fromWorker(worker),
            onTap: () =>
                context.push(WorkersConstants.workerDetailRoute(worker.id)),
          );
        },
      ),
    );
  }

  List<WorkerModel> _applyFilters(List<WorkerModel> workers) {
    return WorkerFilterer.applyToWorkers(
      workers,
      _filterState,
    ).cast<WorkerModel>();
  }
}
