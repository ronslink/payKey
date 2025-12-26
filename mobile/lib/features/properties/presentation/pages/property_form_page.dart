import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
         );
       });
    });
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
        ),
      );
    } else {
      await controller.createProperty(
        CreatePropertyRequest(
          name: formData.name,
          address: formData.address,
          geofenceRadius: formData.geofenceRadius,
          what3words: formData.what3words,
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
            const SizedBox(height: PropertyFormTheme.fieldSpacing),
            _buildGeofenceField(),
            const SizedBox(height: PropertyFormTheme.fieldSpacing),
            _buildWhat3WordsField(),
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
      icon: Icons.my_location,
      keyboardType: TextInputType.number,
      helperText: 'Radius for worker check-in',
      validator: PropertyFormValidators.geofenceRadius,
    );
  }

  Widget _buildWhat3WordsField() {
    return PropertyTextField(
      controller: _controllers.what3words,
      label: 'What3Words (Optional)',
      hint: '///word.word.word',
      icon: Icons.grid_3x3,
      helperText: 'Precise location identifier',
      validator: PropertyFormValidators.what3words,
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
