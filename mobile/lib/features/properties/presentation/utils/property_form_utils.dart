import 'package:flutter/material.dart';
import '../constants/property_form_constants.dart';

// Import your actual models - check paths match your project
// import '../../data/models/property_model.dart';
// Note: We don't import models here to keep utils pure/portable if possible, 
// or you can if strictly tied to domain.

/// Form data for property creation/editing
class PropertyFormData {
  final String name;
  final String address;
  final int geofenceRadius;
  final String? what3words;
  final bool isActive;

  const PropertyFormData({
    required this.name,
    required this.address,
    required this.geofenceRadius,
    this.what3words,
    this.isActive = true,
  });

  /// Create from controllers
  factory PropertyFormData.fromControllers({
    required TextEditingController nameController,
    required TextEditingController addressController,
    required TextEditingController geofenceController,
    required TextEditingController what3wordsController,
    required ValueNotifier<bool> isActiveController,
  }) {
    return PropertyFormData(
      name: nameController.text.trim(),
      address: addressController.text.trim(),
      geofenceRadius: int.tryParse(geofenceController.text) ??
          PropertyFormConstants.defaultGeofenceRadius,
      what3words: what3wordsController.text.trim().isEmpty
          ? null
          : what3wordsController.text.trim(),
      isActive: isActiveController.value,
    );
  }

  /// Check if address appears to be coordinates
  bool get addressIsCoordinates {
    return PropertyFormConstants.coordinatesRegex.hasMatch(address);
  }
}

/// Manages form controllers and their lifecycle
class PropertyFormControllers {
  final TextEditingController name = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController geofence = TextEditingController(
    text: PropertyFormConstants.defaultGeofenceRadius.toString(),
  );
  final TextEditingController what3words = TextEditingController();
  final ValueNotifier<bool> isActive = ValueNotifier<bool>(true);

  /// Populate controllers from existing property
  void populate({
    required String name,
    required String address,
    required int geofenceRadius,
    String? what3words,
    bool isActive = true,
  }) {
    this.name.text = name;
    this.address.text = address;
    geofence.text = geofenceRadius.toString();
    this.what3words.text = what3words ?? '';
    this.isActive.value = isActive;
  }

  /// Get form data from current controller values
  PropertyFormData get formData => PropertyFormData.fromControllers(
        nameController: name,
        addressController: address,
        geofenceController: geofence,
        what3wordsController: what3words,
        isActiveController: isActive,
      );

  /// Dispose all controllers
  void dispose() {
    name.dispose();
    address.dispose();
    geofence.dispose();
    what3words.dispose();
    isActive.dispose();
  }
}

/// Validation helpers
class PropertyFormValidators {
  PropertyFormValidators._();

  /// Validate required field
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  /// Validate geofence radius
  static String? geofenceRadius(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional, will use default
    }

    final radius = int.tryParse(value);
    if (radius == null) {
      return 'Please enter a valid number';
    }

    if (radius < PropertyFormConstants.minGeofenceRadius) {
      return 'Minimum radius is ${PropertyFormConstants.minGeofenceRadius}m';
    }

    if (radius > PropertyFormConstants.maxGeofenceRadius) {
      return 'Maximum radius is ${PropertyFormConstants.maxGeofenceRadius}m';
    }

    return null;
  }

  /// Validate What3Words format
  static String? what3words(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    // Basic What3Words format: ///word.word.word
    final pattern = RegExp(r'^(///)?[a-z]+\.[a-z]+\.[a-z]+$', caseSensitive: false);
    if (!pattern.hasMatch(value.trim())) {
      return 'Format: ///word.word.word';
    }

    return null;
  }
}

/// Address resolution helper
class AddressResolver {
  /// Check if address is coordinate format and return fallback if available
  static String resolveAddress({
    required String propertyAddress,
    String? fallbackAddress,
  }) {
    final isCoordinates = PropertyFormConstants.coordinatesRegex.hasMatch(propertyAddress);

    if (isCoordinates && fallbackAddress != null && fallbackAddress.isNotEmpty) {
      return fallbackAddress;
    }

    return propertyAddress;
  }
}
