import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/property_model.dart';
import '../providers/properties_provider.dart';

class PropertyFormPage extends ConsumerStatefulWidget {
  final String? propertyId;
  
  const PropertyFormPage({super.key, this.propertyId});

  @override
  ConsumerState<PropertyFormPage> createState() => _PropertyFormPageState();
}

class _PropertyFormPageState extends ConsumerState<PropertyFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _geofenceController = TextEditingController(text: '100');
  final _what3wordsController = TextEditingController();
  
  late AnimationController _animationController;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();
    _isEditing = widget.propertyId != null;
    
    if (_isEditing) {
      _loadProperty();
    }
  }

  Future<void> _loadProperty() async {
    // Load existing property if editing
    final selectedProperty = ref.read(selectedPropertyProvider);
    if (selectedProperty != null) {
      _nameController.text = selectedProperty.name;
      _addressController.text = selectedProperty.address;
      _geofenceController.text = selectedProperty.geofenceRadius.toString();
      _what3wordsController.text = selectedProperty.what3words ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _geofenceController.dispose();
    _what3wordsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final controller = ref.read(propertyControllerProvider);
      
      if (_isEditing) {
        await controller.updateProperty(
          widget.propertyId!,
          UpdatePropertyRequest(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            geofenceRadius: int.tryParse(_geofenceController.text) ?? 100,
            what3words: _what3wordsController.text.trim().isEmpty
                ? null
                : _what3wordsController.text.trim(),
          ),
        );
      } else {
        await controller.createProperty(
          CreatePropertyRequest(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            geofenceRadius: int.tryParse(_geofenceController.text) ?? 100,
            what3words: _what3wordsController.text.trim().isEmpty
                ? null
                : _what3wordsController.text.trim(),
          ),
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(_isEditing ? 'Property updated!' : 'Property created!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
          ),
          
          // Decorative Orbs
          Positioned(
            top: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withOpacity(0.15),
                ),
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildFormCard(),
                  ),
                ),
                _buildBottomButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 16),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            ),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Property' : 'Add Property',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEditing ? 'Update property details' : 'Create a new work location',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutQuart,
        )),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.home_work,
                      title: 'Property Details',
                      subtitle: 'Basic information about the location',
                    ),
                    const SizedBox(height: 24),
                    
                    _buildTextField(
                      controller: _nameController,
                      label: 'Property Name',
                      hint: 'e.g. Main Office, Warehouse A',
                      icon: Icons.business,
                      required: true,
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Full physical address',
                      icon: Icons.location_on,
                      required: true,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _geofenceController,
                      label: 'Geofence Radius (meters)',
                      hint: '100',
                      icon: Icons.my_location,
                      keyboardType: TextInputType.number,
                      helperText: 'Radius for worker check-in',
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _what3wordsController,
                      label: 'What3Words (Optional)',
                      hint: '///word.word.word',
                      icon: Icons.grid_3x3,
                      helperText: 'Precise location identifier',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF60A5FA), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            prefixIcon: Icon(icon, color: const Color(0xFF60A5FA)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            helperText: helperText,
            helperStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
          validator: required
              ? (value) => value == null || value.trim().isEmpty
                  ? 'This field is required'
                  : null
              : null,
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF3B82F6).withOpacity(0.5),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: const Color(0xFF3B82F6).withOpacity(0.5),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isEditing ? Icons.save : Icons.add_home_work),
                    const SizedBox(width: 12),
                    Text(
                      _isEditing ? 'Update Property' : 'Create Property',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
