import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/properties_provider.dart';

class PropertyDetailPage extends ConsumerWidget {
  final String propertyId;
  
  const PropertyDetailPage({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyAsync = ref.watch(propertyDetailProvider(propertyId));
    
    return Scaffold(
      appBar: AppBar(
        title: propertyAsync.when(
          data: (property) => Text(property.name),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Property Details'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/properties/edit/$propertyId'),
          ),
        ],
      ),
      body: propertyAsync.when(
        data: (property) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Name
              Text(
                property.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Sample data indicator
              if (property.id.startsWith('preview-'))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Sample Data - Upgrade to PLATINUM for real properties',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),
              
              // Address Section
              _buildInfoCard(
                context,
                icon: Icons.location_on,
                title: 'Address',
                value: property.address,
              ),
              const SizedBox(height: 16),
              
              // Geofence Radius
              _buildInfoCard(
                context,
                icon: Icons.radar,
                title: 'Geofence Radius',
                value: '${property.geofenceRadius} meters',
              ),
              const SizedBox(height: 16),
              
              // Coordinates
              if (property.latitude != null && property.longitude != null)
                _buildInfoCard(
                  context,
                  icon: Icons.my_location,
                  title: 'Coordinates',
                  value: '${property.latitude?.toStringAsFixed(4)}, ${property.longitude?.toStringAsFixed(4)}',
                ),
              if (property.latitude != null) const SizedBox(height: 16),
              
              // What3Words
              if (property.what3words != null)
                _buildInfoCard(
                  context,
                  icon: Icons.grid_on,
                  title: 'What3Words',
                  value: property.what3words!,
                ),
              if (property.what3words != null) const SizedBox(height: 16),
              
              // Worker Count
              _buildInfoCard(
                context,
                icon: Icons.people,
                title: 'Assigned Workers',
                value: '${property.workerCount} workers',
              ),
              const SizedBox(height: 16),
              
              // Status
              _buildInfoCard(
                context,
                icon: property.isActive ? Icons.check_circle : Icons.cancel,
                title: 'Status',
                value: property.isActive ? 'Active' : 'Inactive',
                valueColor: property.isActive ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              
              // Created Date
              if (property.createdAt != null)
                _buildInfoCard(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Created',
                  value: _formatDate(property.createdAt!),
                ),
              const SizedBox(height: 32),
              
              // Actions
              if (property.isActive)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmArchive(context, ref, property.id),
                    icon: const Icon(Icons.archive),
                    label: const Text('Archive Property'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _restoreProperty(context, ref, property.id),
                        icon: const Icon(Icons.restore),
                        label: const Text('Restore Property'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmPermanentDelete(context, ref, property.id),
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Delete Permanently'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(propertyDetailProvider(propertyId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: valueColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _confirmArchive(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Property?'),
        content: const Text('Archived properties will not be available for time tracking.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ref.read(propertyControllerProvider).deleteProperty(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Property archived')));
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _restoreProperty(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(propertyControllerProvider).restoreProperty(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Property restored')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _confirmPermanentDelete(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: const Text('This action cannot be undone. All data related to this property will be lost. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ref.read(propertyControllerProvider).permanentlyDeleteProperty(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Property deleted permanently')));
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
