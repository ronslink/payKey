import 'package:flutter/material.dart';
import '../constants/workers_constants.dart';
import '../utils/worker_filter.dart';

/// Stats row showing total, active, and pending workers
class WorkerStatsRow extends StatelessWidget {
  final WorkerStats stats;

  const WorkerStatsRow({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WorkersTheme.pagePadding,
        8,
        WorkersTheme.pagePadding,
        WorkersTheme.pagePadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              config: WorkerStatConfig.total,
              value: stats.total,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              config: WorkerStatConfig.active,
              value: stats.active,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              config: WorkerStatConfig.pending,
              value: stats.pending,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final WorkerStatConfig config;
  final int value;

  const _StatCard({
    required this.config,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: WorkersTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(config.icon, size: 16, color: config.color),
              const SizedBox(width: 6),
              Text(
                config.label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

/// Search bar for workers
class WorkerSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final VoidCallback onClear;

  const WorkerSearchBar({
    super.key,
    required this.controller,
    required this.query,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WorkersTheme.pagePadding),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: WorkersTheme.cardBackground,
          borderRadius: BorderRadius.circular(WorkersTheme.cardBorderRadius),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey.shade500),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Search name, KRA PIN, phone...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (query.isNotEmpty)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

/// Filter chips for worker status
class WorkerFilterChips extends StatelessWidget {
  final WorkerFilter selectedFilter;
  final ValueChanged<WorkerFilter> onFilterChanged;

  const WorkerFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        WorkersTheme.pagePadding,
        WorkersTheme.pagePadding,
        WorkersTheme.pagePadding,
        8,
      ),
      child: Row(
        children: WorkersConstants.filters.map((filter) {
          return _FilterChip(
            filter: filter,
            isSelected: selectedFilter == filter,
            onTap: () => onFilterChanged(filter),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final WorkerFilter filter;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : WorkersTheme.cardBackground,
            borderRadius: BorderRadius.circular(WorkersTheme.chipBorderRadius),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey.shade300,
            ),
          ),
          child: Text(
            filter.label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// Property dropdown filter
class PropertyFilterDropdown extends StatelessWidget {
  final String? selectedPropertyId;
  final List<dynamic> properties;
  final ValueChanged<String?> onChanged;

  const PropertyFilterDropdown({
    super.key,
    required this.selectedPropertyId,
    required this.properties,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WorkersTheme.pagePadding,
        8,
        WorkersTheme.pagePadding,
        WorkersTheme.pagePadding,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: WorkersTheme.cardBackground,
          borderRadius: BorderRadius.circular(WorkersTheme.cardBorderRadius),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: selectedPropertyId,
            isExpanded: true,
            hint: _buildPropertyRow(
              context,
              Icons.home_work_outlined,
              'All Properties',
              isHint: true,
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: _buildPropertyRow(
                  context,
                  Icons.home_work_outlined,
                  'All Properties',
                  isHint: true,
                ),
              ),
              ...properties.map((p) => DropdownMenuItem<String?>(
                    value: p.id as String,
                    child: _buildPropertyRow(
                      context,
                      Icons.home,
                      p.name as String,
                    ),
                  )),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyRow(
    BuildContext context,
    IconData icon,
    String name, {
    bool isHint = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isHint
              ? Colors.grey.shade600
              : Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: isHint
                ? TextStyle(color: Colors.grey.shade700)
                : null,
          ),
        ),
      ],
    );
  }
}

/// Empty state for workers list
class WorkersEmptyState extends StatelessWidget {
  final bool hasFilters;
  final bool hasSearchQuery;
  final VoidCallback onAddWorker;
  final VoidCallback onClearFilters;

  const WorkersEmptyState({
    super.key,
    required this.hasFilters,
    required this.hasSearchQuery,
    required this.onAddWorker,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearchQuery ? Icons.search_off : Icons.people_outline,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearchQuery ? 'No matches found' : 'No workers yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 16),
          if (!hasFilters)
            ElevatedButton.icon(
              onPressed: onAddWorker,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add First Worker'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          if (hasFilters)
            TextButton(
              onPressed: onClearFilters,
              child: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }
}

/// Error state for workers list
class WorkersErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const WorkersErrorState({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text('Failed to load workers'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
