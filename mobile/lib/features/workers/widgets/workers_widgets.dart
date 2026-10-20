import 'package:flutter/material.dart';
import '../../../core/widgets/responsive_card_grid.dart';
import '../constants/workers_constants.dart';
import '../utils/worker_filter.dart';

/// Optional property setup prompt, with presentation independent of navigation.
class PropertySetupPrompt extends StatelessWidget {
  const PropertySetupPrompt({
    super.key,
    required this.onShowInfo,
    required this.onAddProperty,
    required this.onDismiss,
  });

  final VoidCallback onShowInfo;
  final VoidCallback onAddProperty;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _propertyAccent(context);
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: WorkersTheme.pagePadding,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.08),
          WorkersTheme.cardBackground(context),
        ),
        borderRadius: BorderRadius.circular(WorkersTheme.cardBorderRadius),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onShowInfo,
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.home_work_outlined,
                            color: accent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Set Up Property',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Optional: Enable geofencing for time tracking',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: theme.colorScheme.onSurfaceVariant,
                tooltip: 'Dismiss',
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ElevatedButton(
              onPressed: onAddProperty,
              child: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
}

Color _propertyAccent(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFC4B5FD)
    : const Color(0xFF7C3AED);

/// Scrollable explanation; both actions retain their supplied page callbacks.
class PropertyInfoDialog extends StatelessWidget {
  const PropertyInfoDialog({
    super.key,
    required this.onMaybeLater,
    required this.onAddProperty,
  });

  final VoidCallback onMaybeLater;
  final VoidCallback onAddProperty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AlertDialog(
      scrollable: true,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.home_work_rounded,
            color: _propertyAccent(context),
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Property Management')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PropertyFeatureItem(
            icon: Icons.location_on_outlined,
            title: 'Geofencing for Time Tracking',
            description:
                'Workers can only clock in/out when physically at the property location. Without a property setup, geofencing is not available.',
          ),
          const SizedBox(height: 16),
          const _PropertyFeatureItem(
            icon: Icons.business_outlined,
            title: 'Multi-Property Payroll',
            description:
                'Track payroll separately for each property. Assign workers to specific locations and generate reports per property.',
          ),
          const SizedBox(height: 16),
          const _PropertyFeatureItem(
            icon: Icons.groups_outlined,
            title: 'Worker Assignment',
            description:
                'Assign workers to specific properties for organized workforce management across multiple locations.',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property setup is optional',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'You can still add workers and run payroll without properties. Only set up properties if you need geofencing for time tracking or manage multiple locations.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: onMaybeLater,
          child: const Text('Maybe Later'),
        ),
        ElevatedButton(
          onPressed: onAddProperty,
          child: const Text('Add Property'),
        ),
      ],
    );
  }
}

class _PropertyFeatureItem extends StatelessWidget {
  const _PropertyFeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _propertyAccent(context), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Stats row showing total, active, and pending workers
class WorkerStatsRow extends StatelessWidget {
  final WorkerStats stats;

  const WorkerStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WorkersTheme.pagePadding,
        8,
        WorkersTheme.pagePadding,
        WorkersTheme.pagePadding,
      ),
      child: ResponsiveCardGrid(
        minColumnWidth: 100,
        children: [
          _StatCard(config: WorkerStatConfig.total, value: stats.total),
          _StatCard(config: WorkerStatConfig.active, value: stats.active),
          _StatCard(config: WorkerStatConfig.pending, value: stats.pending),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final WorkerStatConfig config;
  final int value;

  const _StatCard({required this.config, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: WorkersTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(config.icon, size: 16, color: config.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  config.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search name, KRA PIN, phone...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 20),
                )
              : null,
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
    final colors = Theme.of(context).colorScheme;
    final primaryColor = colors.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : WorkersTheme.cardBackground(context),
            borderRadius: BorderRadius.circular(WorkersTheme.chipBorderRadius),
            border: Border.all(
              color: isSelected ? primaryColor : Theme.of(context).dividerColor,
            ),
          ),
          child: Text(
            filter.label,
            style: TextStyle(
              color: isSelected ? colors.onPrimary : colors.onSurface,
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
          color: WorkersTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
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
              ...properties.map(
                (p) => DropdownMenuItem<String?>(
                  value: p.id as String,
                  child: _buildPropertyRow(
                    context,
                    Icons.home,
                    p.name as String,
                  ),
                ),
              ),
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
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: isHint
                ? TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                : TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (!hasFilters)
            ElevatedButton.icon(
              onPressed: onAddWorker,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add First Worker'),
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

  const WorkersErrorState({super.key, required this.onRetry});

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
          ),
        ],
      ),
    );
  }
}
