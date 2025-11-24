import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stub provider for properties - feature incomplete
// This is a temporary stub to allow the app to build
// TODO: Implement full properties feature

class Property {
  final String id;
  final String name;
  final String address;
  final int workerCount;
  final double geofenceRadius;
  
  Property({
    required this.id,
    required this.name,
    this.address = '',
    this.workerCount = 0,
    this.geofenceRadius = 100.0,
  });
}

final propertiesProvider = FutureProvider<List<Property>>((ref) async {
  // TODO: Fetch from API
  return [];
});

final selectedPropertyProvider = StateProvider<Property?>((ref) => null);
