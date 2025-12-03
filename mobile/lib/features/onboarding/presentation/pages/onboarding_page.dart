import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/countries_provider.dart';
import '../../../../core/network/api_service.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  late AnimationController _animationController;
  
  int _currentStep = 0;
  final int _totalSteps = 4;
  
  // Track step completion
  final Set<int> _completedSteps = {};
  
  // Personal Details
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  // Identification
  String? _selectedIdType;
  final _idNumberController = TextEditingController();
  String? _selectedNationalityId;
  
  // Tax & Compliance
  final _kraPinController = TextEditingController();
  bool _isResident = true;
  String? _countryOfOrigin;
  final _nssfController = TextEditingController();
  final _nhifController = TextEditingController();
  
  // Location
  String? _selectedCountryId;
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idNumberController.dispose();
    _kraPinController.dispose();
    _nssfController.dispose();
    _nhifController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      await apiService.updateUserProfile({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'idType': _selectedIdType,
        'idNumber': _idNumberController.text.trim(),
        'nationalityId': _selectedNationalityId,
        'kraPin': _kraPinController.text.trim(),
        'isResident': _isResident,
        if (!_isResident && _countryOfOrigin != null) 'countryOfOrigin': _countryOfOrigin,
        if (_nssfController.text.isNotEmpty) 'nssfNumber': _nssfController.text.trim(),
        if (_nhifController.text.isNotEmpty) 'nhifNumber': _nhifController.text.trim(),
        'countryId': _selectedCountryId,
        if (_cityController.text.isNotEmpty) 'city': _cityController.text.trim(),
        if (_addressController.text.isNotEmpty) 'address': _addressController.text.trim(),
      });

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Profile completed successfully!'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Navigate after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go('/home');
        }
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

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (_validateCurrentStep()) {
        _completedSteps.add(_currentStep);
        setState(() => _currentStep++);
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
        _animationController.reset();
        _animationController.forward();
      }
    } else {
      if (_validateCurrentStep()) {
        _completedSteps.add(_currentStep);
        _submit();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      _animationController.reset();
      _animationController.forward();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_firstNameController.text.trim().isEmpty || 
            _lastNameController.text.trim().isEmpty) {
          _showValidationError('Please enter your full name');
          return false;
        }
        return true;
      case 1:
        if (_selectedIdType == null) {
          _showValidationError('Please select your ID type');
          return false;
        }
        if (_idNumberController.text.trim().isEmpty) {
          _showValidationError('Please enter your ID number');
          return false;
        }
        if (_selectedNationalityId == null) {
          _showValidationError('Please select your nationality');
          return false;
        }
        return true;
      case 2:
        if (_kraPinController.text.trim().isEmpty) {
          _showValidationError('KRA PIN is required for tax compliance');
          return false;
        }
        if (!_isResident && _countryOfOrigin == null) {
          _showValidationError('Please select your country of origin');
          return false;
        }
        return true;
      case 3:
        if (_selectedCountryId == null) {
          _showValidationError('Please select your country of residence');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countriesState = ref.watch(countriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPersonalDetailsStep(),
                    _buildIdentificationStep(countriesState),
                    _buildTaxComplianceStep(countriesState),
                    _buildLocationStep(countriesState),
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6),
            const Color(0xFF2563EB),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_circle,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete Your Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Just a few more details to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isCompleted = _completedSteps.contains(index);
              final isCurrent = index == _currentStep;
              
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: isCompleted || isCurrent
                              ? const LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                )
                              : null,
                          color: isCompleted || isCurrent ? null : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < _totalSteps - 1) const SizedBox(width: 8),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStepTitle(_currentStep),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Step ${_currentStep + 1} of $_totalSteps',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Personal Details';
      case 1: return 'Identification';
      case 2: return 'Tax & Compliance';
      case 3: return 'Location';
      default: return '';
    }
  }

  Widget _buildStepCard({required List<Widget> children}) {
    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        )),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalDetailsStep() {
    return _buildStepCard(
      children: [
        _buildSectionHeader(
          icon: Icons.person,
          title: 'Personal Information',
          subtitle: 'Tell us about yourself',
        ),
        const SizedBox(height: 24),
        _buildTextField(
          _firstNameController,
          'First Name',
          'Enter your first name',
          required: true,
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _lastNameController,
          'Last Name',
          'Enter your last name',
          required: true,
          icon: Icons.person_outline,
        ),
      ],
    );
  }

  Widget _buildIdentificationStep(List<dynamic> countries) {
    return _buildStepCard(
      children: [
        _buildSectionHeader(
          icon: Icons.badge,
          title: 'Identification',
          subtitle: 'Verify your identity',
        ),
        const SizedBox(height: 24),
        _buildDropdown(
          value: _selectedIdType,
          label: 'ID Type',
          hint: 'Select your ID type',
          icon: Icons.badge_outlined,
          items: const [
            DropdownMenuItem(value: 'NATIONAL_ID', child: Text('National ID')),
            DropdownMenuItem(value: 'ALIEN_ID', child: Text('Alien ID')),
            DropdownMenuItem(value: 'PASSPORT', child: Text('Passport')),
          ],
          onChanged: (value) => setState(() => _selectedIdType = value),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _idNumberController,
          'ID / Passport Number',
          'Enter your ID number',
          required: true,
          icon: Icons.credit_card,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          value: _selectedNationalityId,
          label: 'Nationality',
          hint: 'Select your nationality',
          icon: Icons.flag_outlined,
          items: countries.map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(
            value: c.id as String,
            child: Text(c.name as String),
          )).toList(),
          onChanged: (value) => setState(() => _selectedNationalityId = value),
        ),
      ],
    );
  }

  Widget _buildTaxComplianceStep(List<dynamic> countries) {
    return _buildStepCard(
      children: [
        _buildSectionHeader(
          icon: Icons.account_balance,
          title: 'Tax & Compliance',
          subtitle: 'Required for payroll processing',
        ),
        const SizedBox(height: 24),
        _buildTextField(
          _kraPinController,
          'KRA PIN',
          'e.g., A000000000A',
          required: true,
          icon: Icons.account_balance_outlined,
          helperText: 'Your Kenya Revenue Authority PIN',
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF3B82F6).withOpacity(0.05),
                const Color(0xFF2563EB).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF3B82F6).withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.home_outlined,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Residency Status',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you a Kenya resident for tax purposes?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildResidencyOption(
                      label: 'Yes, I am a resident',
                      value: true,
                      groupValue: _isResident,
                      onChanged: (value) => setState(() {
                        _isResident = value!;
                        if (_isResident) _countryOfOrigin = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildResidencyOption(
                      label: 'No, I am not',
                      value: false,
                      groupValue: _isResident,
                      onChanged: (value) => setState(() => _isResident = value!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!_isResident) ...[
          const SizedBox(height: 16),
          _buildDropdown(
            value: _countryOfOrigin,
            label: 'Country of Origin',
            hint: 'Select your country',
            icon: Icons.public,
            items: countries.map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(
              value: c.id as String,
              child: Text(c.name as String),
            )).toList(),
            onChanged: (value) => setState(() => _countryOfOrigin = value),
          ),
        ],
        const SizedBox(height: 16),
        _buildTextField(
          _nssfController,
          'NSSF Number (Optional)',
          'Enter NSSF number',
          icon: Icons.security_outlined,
          helperText: 'National Social Security Fund',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _nhifController,
          'NHIF/SHIF Number (Optional)',
          'Enter NHIF number',
          icon: Icons.local_hospital_outlined,
          helperText: 'Social Health Insurance Fund',
        ),
      ],
    );
  }

  Widget _buildLocationStep(List<dynamic> countries) {
    return _buildStepCard(
      children: [
        _buildSectionHeader(
          icon: Icons.location_on,
          title: 'Location Details',
          subtitle: 'Where are you based?',
        ),
        const SizedBox(height: 24),
        _buildDropdown(
          value: _selectedCountryId,
          label: 'Country of Residence',
          hint: 'Select your country',
          icon: Icons.location_on_outlined,
          items: countries.map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(
            value: c.id as String,
            child: Text(c.name as String),
          )).toList(),
          onChanged: (value) => setState(() => _selectedCountryId = value),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _cityController,
          'City / County (Optional)',
          'e.g., Nairobi',
          icon: Icons.location_city_outlined,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _addressController,
          'Physical Address (Optional)',
          'Enter your address',
          icon: Icons.home_outlined,
          maxLines: 3,
        ),
      ],
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
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResidencyOption({
    required String label,
    required bool value,
    required bool groupValue,
    required ValueChanged<bool?> onChanged,
  }) {
    final isSelected = value == groupValue;
    
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: const Color(0xFF3B82F6).withOpacity(0.3),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == _totalSteps - 1 ? 'Complete Setup' : 'Continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentStep == _totalSteps - 1 ? Icons.check : Icons.arrow_forward,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool required = false,
    IconData? icon,
    String? helperText,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        helperStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        prefixIcon: icon != null ? Icon(icon, color: Color(0xFF6B7280)) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return '$label is required';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}
