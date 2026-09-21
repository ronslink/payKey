import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Core imports
import '../../../../core/network/api_service.dart';
import '../../../../core/utils/location_utils.dart';
import '../../../../core/utils/plus_code.dart';

// Domain imports
import '../../data/models/property_model.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/properties_provider.dart';

// Local imports
import '../constants/property_form_constants.dart';
import '../widgets/property_form_widgets.dart';
import '../utils/property_form_utils.dart';

/// Property form page for creating and editing properties
class PropertyFormPage extends ConsumerStatefulWidget {
  final String? propertyId;

  const PropertyFormPage({super.key, this.propertyId});

  @override
  ConsumerState<PropertyFormPage> createState() => _PropertyFormPageState();
}

class _PropertyFormPageState extends ConsumerState<PropertyFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _controllers = PropertyFormControllers();

  late AnimationController _animationController;
  bool _isLoading = false;
  bool _isLocating = false;
  bool _isLookingUpWords = false;
  String? _resolvedPlace;

  /// Whether we're editing an existing property
  bool get _isEditing => widget.propertyId != null;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    if (_isEditing) {
      _loadExistingProperty();
    }
  }

  void _initAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: PropertyFormConstants.animationDuration,
    );
    _animationController.forward();
  }

  void _loadExistingProperty() {
    // We defer this slightly to ensure provider is ready or just run immediately
    // Using simple microtask or just normally
    WidgetsBinding.instance.addPostFrameCallback((_) async {
       final selectedProperty = ref.read(selectedPropertyProvider);
       if (selectedProperty == null) return;

       final profileState = ref.read(profileProvider);
       final fallbackAddress = profileState.hasValue
           ? profileState.value?.address
           : null;

       final resolvedAddress = AddressResolver.resolveAddress(
         propertyAddress: selectedProperty.address,
         fallbackAddress: fallbackAddress,
       );

       setState(() {
         _controllers.populate(
           name: selectedProperty.name,
           address: resolvedAddress,
           geofenceRadius: selectedProperty.geofenceRadius,
           what3words: selectedProperty.what3words,
           isActive: selectedProperty.isActive,
           latitude: selectedProperty.latitude,
           longitude: selectedProperty.longitude,
         );
       });
    });
  }

  // ===========================================================================
  // LOCATION CAPTURE
  // ===========================================================================

  /// Capture the pin by standing at the site — the most reliable option where
  /// street addresses are not enough to find a workplace.
  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final position = await LocationUtils.currentPosition();
      _controllers.setPin(position.latitude, position.longitude);
      setState(() {});
      _showMessage(
        'Pin captured within about ${position.accuracy.round()} m. '
        'Check it matches the gate or entrance.',
        isError: false,
      );

      // Best effort: label the pin with its what3words address so it can be
      // shared with staff. The lookup needs a server API key and is optional.
      if (_controllers.what3words.text.trim().isEmpty) {
        await _describePinWithWhat3words(
          position.latitude,
          position.longitude,
          silent: true,
        );
      }
    } on LocationException catch (e) {
      _showMessage(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// Turn a what3words address into the coordinates the geofence measures from.
  Future<void> _lookUpWhat3words() async {
    final words = _controllers.what3words.text.trim();
    if (words.isEmpty) {
      _showMessage(
        'Enter the three words for this site, for example filled.count.soap.',
        isError: true,
      );
      return;
    }

    setState(() => _isLookingUpWords = true);
    try {
      final response = await ApiService().properties.resolveWhat3words(words);
      final data = response.data as Map<String, dynamic>;
      final latitude = (data['latitude'] as num).toDouble();
      final longitude = (data['longitude'] as num).toDouble();

      _controllers.setPin(latitude, longitude);
      setState(() {
        _resolvedPlace = data['nearestPlace'] as String?;
      });
      _showMessage(
        _resolvedPlace == null
            ? 'Pin set from what3words.'
            : 'Pin set near $_resolvedPlace.',
        isError: false,
      );
    } on DioException catch (e) {
      _showMessage(
        _messageFromDio(e) ??
            'Could not look up those words. Use your current location instead.',
        isError: true,
      );
    } catch (e) {
      _showMessage('Could not look up those words: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLookingUpWords = false);
    }
  }

  Future<void> _describePinWithWhat3words(
    double latitude,
    double longitude, {
    bool silent = false,
  }) async {
    try {
      final response = await ApiService().properties.resolveWords(
        latitude,
        longitude,
      );
      final data = response.data as Map<String, dynamic>;
      final words = data['words'] as String?;
      if (words == null || !mounted) return;

      _controllers.what3words.text = words;
      setState(() {
        _resolvedPlace = data['nearestPlace'] as String?;
      });
    } on DioException catch (e) {
      final message = _messageFromDio(e);
      if (!silent && message != null) _showMessage(message, isError: true);
    } catch (_) {
      // The pin is already captured; the label is a convenience.
    }
  }

  String? _messageFromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String) return message;
      if (message is List && message.isNotEmpty) return message.first.toString();
    }
    return null;
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      isError
          ? PropertyFormSnackbars.error(message)
          : PropertyFormSnackbars.success(message),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controllers.dispose();
    super.dispose();
  }

  // ===========================================================================
  // FORM SUBMISSION
  // ===========================================================================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // A geofence measures from one pin, so half a pin is not usable.
    if (_controllers.formData.hasPartialPin) {
      _showMessage(
        'A geofence pin needs both a latitude and a longitude.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _performSubmission();
      _onSubmitSuccess();
    } catch (e) {
      _onSubmitError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _performSubmission() async {
    final controller = ref.read(propertyControllerProvider);
    final formData = _controllers.formData;

    if (_isEditing) {
      await controller.updateProperty(
        widget.propertyId!,
        UpdatePropertyRequest(
          name: formData.name,
          address: formData.address,
          geofenceRadius: formData.geofenceRadius,
          what3words: formData.what3words,
          isActive: formData.isActive,
          latitude: formData.latitude,
          longitude: formData.longitude,
        ),
      );
    } else {
      await controller.createProperty(
        CreatePropertyRequest(
          name: formData.name,
          address: formData.address,
          geofenceRadius: formData.geofenceRadius,
          what3words: formData.what3words,
          latitude: formData.latitude,
          longitude: formData.longitude,
          // isActive is not supported in Create DTO yet, defaults to true
        ),
      );
    }
  }

  void _onSubmitSuccess() {
    if (!mounted) return;

    final message = _isEditing ? 'Property updated!' : 'Property created!';
    ScaffoldMessenger.of(context).showSnackBar(
      PropertyFormSnackbars.success(message),
    );
    context.pop();
  }

  void _onSubmitError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      PropertyFormSnackbars.error('Error: $error'),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PropertyFormBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(PropertyFormTheme.cardPadding),
                  child: _buildFormCard(),
                ),
              ),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return PropertyFormHeader(
      title: _isEditing ? 'Edit Property' : 'Add Property',
      subtitle: _isEditing ? 'Update property details' : 'Create a new work location',
      onBack: () => context.pop(),
    );
  }

  Widget _buildFormCard() {
    return GlassCard(
      animation: _animationController,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FormSectionHeader(
              icon: Icons.home_work,
              title: 'Property Details',
              subtitle: 'Basic information about the location',
            ),
            const SizedBox(height: PropertyFormTheme.cardPadding),
            _buildNameField(),
            const SizedBox(height: PropertyFormTheme.fieldSpacing),
            _buildAddressField(),
            const SizedBox(height: PropertyFormTheme.sectionSpacing),
            const FormSectionHeader(
              icon: Icons.my_location,
              title: 'Location & Geofence',
              subtitle: 'Where employees must be to clock in',
            ),
            const SizedBox(height: PropertyFormTheme.fieldSpacing),
            _buildLocationCapture(),
            const SizedBox(height: PropertyFormTheme.fieldSpacing),
            _buildWhat3WordsField(),
            const SizedBox(height: PropertyFormTheme.fieldSpacing),
            _buildCoordinatesFields(),
            const SizedBox(height: PropertyFormTheme.fieldSpacing),
            _buildGeofenceField(),
            const SizedBox(height: PropertyFormTheme.fieldSpacing),
            _buildPinSummary(),
            if (_isEditing) ...[
              const SizedBox(height: PropertyFormTheme.fieldSpacing),
              _buildIsActiveSwitch(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return PropertyTextField(
      controller: _controllers.name,
      label: 'Property Name',
      hint: 'e.g. Main Office, Warehouse A',
      icon: Icons.business,
      required: true,
      validator: PropertyFormValidators.required,
    );
  }

  Widget _buildAddressField() {
    return PropertyTextField(
      controller: _controllers.address,
      label: 'Address',
      hint: 'Full physical address',
      icon: Icons.location_on,
      required: true,
      maxLines: 2,
      validator: PropertyFormValidators.required,
    );
  }

  Widget _buildGeofenceField() {
    return PropertyTextField(
      controller: _controllers.geofence,
      label: 'Geofence Radius (meters)',
      hint: '${PropertyFormConstants.defaultGeofenceRadius}',
      icon: Icons.radar,
      keyboardType: TextInputType.number,
      helperText: 'How far from the pin a clock-in is still accepted',
      validator: PropertyFormValidators.geofenceRadius,
    );
  }

  Widget _buildLocationCapture() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PropertyActionButton(
          icon: Icons.gps_fixed,
          label: 'Use my current location',
          busy: _isLocating,
          onPressed: _useCurrentLocation,
        ),
        const SizedBox(height: 8),
        Text(
          'Stand at the gate or entrance of the site when you capture the pin, '
          'or set it from a what3words address below.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildCoordinatesFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: PropertyTextField(
            controller: _controllers.latitude,
            label: 'Latitude',
            hint: '-1.286389',
            icon: Icons.pin_drop,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            validator: PropertyFormValidators.latitude,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PropertyTextField(
            controller: _controllers.longitude,
            label: 'Longitude',
            hint: '36.817223',
            icon: Icons.pin_drop_outlined,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            validator: PropertyFormValidators.longitude,
          ),
        ),
      ],
    );
  }

  Widget _buildPinSummary() {
    // Rebuild whenever anything the summary describes changes.
    return ListenableBuilder(
      listenable: Listenable.merge([
        _controllers.latitude,
        _controllers.longitude,
        _controllers.geofence,
        _controllers.what3words,
        _controllers.address,
      ]),
      builder: (context, _) {
        return PropertyPinSummary(
          latitude: double.tryParse(_controllers.latitude.text.trim()),
          longitude: double.tryParse(_controllers.longitude.text.trim()),
          radiusMeters: int.tryParse(_controllers.geofence.text) ??
              PropertyFormConstants.defaultGeofenceRadius,
          what3words: _controllers.what3words.text.trim(),
          resolvedPlace: _resolvedPlace,
          onAddToAddress: _addPlusCodeToAddress,
        );
      },
    );
  }

  /// Folds the pin's Plus Code into the address text.
  ///
  /// The address is already stored, so this is how a precise, shareable
  /// location survives without a schema change. It is idempotent: adding the
  /// same code twice does nothing.
  void _addPlusCodeToAddress() {
    final latitude = double.tryParse(_controllers.latitude.text.trim());
    final longitude = double.tryParse(_controllers.longitude.text.trim());
    if (latitude == null || longitude == null) return;

    final code = PlusCode.encode(latitude, longitude);
    final address = _controllers.address.text.trim();
    if (address.contains(code)) {
      _showMessage('That Plus Code is already in the address.', isError: false);
      return;
    }

    _controllers.address.text = address.isEmpty ? code : '$address ($code)';
    _showMessage('Plus Code added to the address.', isError: false);
  }

  Widget _buildWhat3WordsField() {
    return PropertyTextField(
      controller: _controllers.what3words,
      label: 'What3Words (Optional)',
      hint: '///word.word.word',
      icon: Icons.grid_3x3,
      helperText: 'Precise location identifier',
      validator: PropertyFormValidators.what3words,
      actionLabel: 'Look up coordinates',
      actionBusy: _isLookingUpWords,
      onAction: _lookUpWhat3words,
    );
  }

  Widget _buildIsActiveSwitch() {
    return ValueListenableBuilder<bool>(
      valueListenable: _controllers.isActive,
      builder: (context, isActive, child) {
        return SwitchListTile(
          value: isActive,
          onChanged: (value) => _controllers.isActive.value = value,
          title: const Text(
            'Active Property',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            isActive ? 'Workers can clock in here' : 'Property disabled',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
          secondary: Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            color: isActive ? PropertyFormTheme.successGreen : PropertyFormTheme.errorRed,
          ),
          activeTrackColor: PropertyFormTheme.successGreen,
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }

  Widget _buildBottomButton() {
    return PropertySubmitButton(
      isLoading: _isLoading,
      isEditing: _isEditing,
      onPressed: _submit,
    );
  }
}
