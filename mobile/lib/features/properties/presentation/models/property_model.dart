// Stub model for Property - feature incomplete
class PropertyModel {
  final String id;
  final String name;
  final String address;
  final int workerCount;
  final double geofenceRadius;
  
  PropertyModel({
    required this.id,
    required this.name,
    required this.address,
    this.workerCount = 0,
    this.geofenceRadius = 100.0,
  });
}
