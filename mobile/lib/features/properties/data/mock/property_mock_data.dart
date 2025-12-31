import '../models/property_model.dart';

/// Mock data for Property Management feature preview mode.
/// 
/// This data is shown to users who don't have PLATINUM subscription
/// but are viewing the Property Management feature in preview mode.
class PropertyMockData {
  /// Sample properties for preview mode
  static List<PropertyModel> get properties => [
    PropertyModel(
      id: 'preview-property-001',
      name: 'Main Residence (Sample)',
      address: '123 Nairobi Way, Westlands - Sample Data',
      userId: 'preview-user',
      geofenceRadius: 100,
      isActive: true,
      latitude: -1.2921,
      longitude: 36.8219,
      workerCount: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    PropertyModel(
      id: 'preview-property-002',
      name: 'Beach House (Sample)',
      address: '456 Diani Beach Road - Sample Data',
      userId: 'preview-user',
      geofenceRadius: 150,
      isActive: true,
      latitude: -4.3167,
      longitude: 39.5833,
      workerCount: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  /// Get a single mock property by ID
  static PropertyModel getProperty(String id) => 
      properties.firstWhere(
        (p) => p.id == id,
        orElse: () => properties.first,
      );
}
