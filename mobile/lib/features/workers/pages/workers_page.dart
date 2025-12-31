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
        _propertyPromptDismissed = prefs.getBool(_kPropertyPromptDismissed) ?? false;
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
    // Check if user is PLATINUM tier
    final summaryAsync = ref.watch(subscriptionSummaryProvider);
    final isPlatinum = summaryAsync.when(
      data: (summary) => summary.tier.toUpperCase() == 'PLATINUM',
      loading: () => false,
      error: (_, __) => false,
    );

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text('My Workforce'),
      actions: [
        // Properties button for PLATINUM users
        if (isPlatinum)
          IconButton(
            icon: const Icon(Icons.home_work_outlined),
            tooltip: 'Manage Properties',
            onPressed: () => context.push('/properties'),
          ),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            const Color(0xFF7C3AED).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showPropertyInfoDialog(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.home_work_outlined,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showPropertyInfoDialog(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Set Up Property',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Optional: Enable geofencing for time tracking',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => context.push('/properties/add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text('Add'),
              ),
              const SizedBox(width: 4),
              // Dismiss button
              IconButton(
                icon: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Dismiss',
                onPressed: () => _dismissPropertyPrompt(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPropertyInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Property Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),

              // Features List
              _buildFeatureItem(
                Icons.location_on_outlined,
                'Geofencing for Time Tracking',
                'Workers can only clock in/out when physically at the property location. Without a property setup, geofencing is not available.',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.business_outlined,
                'Multi-Property Payroll',
                'Track payroll separately for each property. Assign workers to specific locations and generate reports per property.',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.groups_outlined,
                'Worker Assignment',
                'Assign workers to specific properties for organized workforce management across multiple locations.',
              ),

              const SizedBox(height: 20),

              // Info box - clarify this is optional
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Property setup is optional',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You can still add workers and run payroll without properties. Only set up properties if you need geofencing for time tracking or manage multiple locations.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Maybe Later'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.push('/properties/add');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Add Property'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF8B5CF6),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
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
