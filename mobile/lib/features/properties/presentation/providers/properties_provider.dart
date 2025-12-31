import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/property_model.dart';
import '../../data/repositories/properties_repository.dart';

/// Provider for fetching all properties with 403 fallback (via repository)
final propertiesProvider = FutureProvider<List<PropertyModel>>((ref) async {
  final repository = ref.watch(propertiesRepositoryProvider);
  return repository.getProperties();
});

/// Provider for fetching a single property with 403 fallback (via repository)
final propertyDetailProvider = FutureProvider.family<PropertyModel, String>((ref, id) async {
  final repository = ref.watch(propertiesRepositoryProvider);
  return repository.getProperty(id);
});

/// Provider for property summaries with 403 fallback (via repository)
final propertySummariesProvider = FutureProvider<List<PropertyModel>>((ref) async {
  final repository = ref.watch(propertiesRepositoryProvider);
  return repository.getPropertySummaries();
});

// Controllers
class SelectedPropertyNotifier extends Notifier<PropertyModel?> {
  @override
  PropertyModel? build() => null;
  
  void set(PropertyModel? value) => state = value;
}

final selectedPropertyProvider = 
    NotifierProvider<SelectedPropertyNotifier, PropertyModel?>(SelectedPropertyNotifier.new);

// Actions
final propertyControllerProvider = Provider((ref) {
  return PropertyController(ref);
});

class PropertyController {
  final Ref _ref;

  PropertyController(this._ref);

  Future<void> createProperty(CreatePropertyRequest request) async {
    final repository = _ref.read(propertiesRepositoryProvider);
    await repository.createProperty(request);
    _ref.invalidate(propertiesProvider);
  }

  Future<void> updateProperty(String id, UpdatePropertyRequest request) async {
    final repository = _ref.read(propertiesRepositoryProvider);
    await repository.updateProperty(id, request);
    _ref.invalidate(propertiesProvider);
    _ref.invalidate(propertyDetailProvider(id));
  }

  Future<void> deleteProperty(String id) async {
    final repository = _ref.read(propertiesRepositoryProvider);
    await repository.deleteProperty(id);
    _ref.invalidate(propertiesProvider);
  }
}
