import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/property_model.dart';
import 'package:dio/dio.dart';

// Service Provider
final propertyServiceProvider = Provider<PropertyEndpoints>((ref) {
  return ref.watch(apiServiceProvider).properties;
});

// Providers
final propertiesProvider = FutureProvider<List<PropertyModel>>((ref) async {
  final service = ref.watch(propertyServiceProvider);
  final response = await service.getAll();
  
  // Parse list
  final List<dynamic> data = response.data;
  return data.map((json) => PropertyModel.fromJson(json)).toList();
});

final propertyDetailProvider = FutureProvider.family<PropertyModel, String>((ref, id) async {
  final service = ref.watch(propertyServiceProvider);
  final response = await service.getById(id);
  return PropertyModel.fromJson(response.data);
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
    final service = _ref.read(propertyServiceProvider);
    await service.create(request.toJson());
    _ref.invalidate(propertiesProvider);
  }

  Future<void> updateProperty(String id, UpdatePropertyRequest request) async {
    final service = _ref.read(propertyServiceProvider);
    await service.update(id, request.toJson());
    _ref.invalidate(propertiesProvider);
    _ref.invalidate(propertyDetailProvider(id));
  }

  Future<void> deleteProperty(String id) async {
    final service = _ref.read(propertyServiceProvider);
    await service.delete(id);
    _ref.invalidate(propertiesProvider);
  }
}
