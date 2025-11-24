import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/properties_provider.dart';

class PropertyDetailPage extends ConsumerWidget {
  final String propertyId;
  
  const PropertyDetailPage({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = ref.watch(selectedPropertyProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(property?.name ?? 'Property Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/properties/edit/$propertyId'),
          ),
        ],
      ),
      body: property == null
          ? const Center(child: Text('Property not found'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  const Text('Property details will be displayed here'),
                ],
              ),
            ),
    );
  }
}
