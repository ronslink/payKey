import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Domain imports
import '../data/models/worker_model.dart';
import '../presentation/providers/workers_provider.dart';
import '../../properties/presentation/providers/properties_provider.dart';

// Local imports
import '../constants/workers_constants.dart';
import '../utils/worker_filter.dart';

import '../widgets/workers_widgets.dart';
import '../widgets/worker_card.dart';

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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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
      backgroundColor: WorkersTheme.backgroundColor,
      appBar: _buildAppBar(context),
      floatingActionButton: _buildFab(context),
      body: Column(
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
          Expanded(
            child: _buildWorkersList(workersAsync),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text('My Workforce'),
      actions: [
          IconButton(
            icon: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Icon(Icons.upload_file_outlined),
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
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.add, color: Colors.white),
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
    final propertiesAsync = ref.watch(propertiesProvider);

    return propertiesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (properties) => PropertyFilterDropdown(
        selectedPropertyId: _filterState.propertyId,
        properties: properties,
        onChanged: _updatePropertyFilter,
      ),
    );
  }

  Widget _buildWorkersList(AsyncValue<List<WorkerModel>> workersAsync) {
    return workersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => WorkersErrorState(
        onRetry: () => ref.invalidate(workersProvider),
      ),
      data: (workers) => _buildFilteredList(workers),
    );
  }

  Widget _buildFilteredList(List<WorkerModel> workers) {
    final filtered = _applyFilters(workers);

    if (filtered.isEmpty) {
      return WorkersEmptyState(
        hasFilters: _filterState.hasActiveFilters,
        hasSearchQuery: _filterState.searchQuery.isNotEmpty,
        onAddWorker: () => context.push(WorkersConstants.addWorkerRoute),
        onClearFilters: _clearFilters,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        WorkersTheme.pagePadding,
        0,
        WorkersTheme.pagePadding,
        100,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final worker = filtered[index];
        return WorkerCard(
          data: WorkerCardData.fromWorker(worker),
          onTap: () => context.push(WorkersConstants.workerDetailRoute(worker.id)),
        );
      },
    );
  }

  List<WorkerModel> _applyFilters(List<WorkerModel> workers) {
    return WorkerFilterer.applyToWorkers(workers, _filterState)
        .cast<WorkerModel>();
  }
}
