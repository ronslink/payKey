import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/countries_provider.dart';
import '../providers/tour_progress_provider.dart';
import '../../data/models/country_model.dart';
import '../../../../core/network/api_service.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with SingleTickerProviderStateMixin {
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

  // Payment & Business
  final _businessNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _mpesaPhoneController = TextEditingController();
  final _mpesaPaybillController = TextEditingController();
  final _mpesaTillController = TextEditingController();

  // Payroll Settings
  String _payrollFrequency = 'MONTHLY';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
    _businessNameController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _mpesaPhoneController.dispose();
    _mpesaPaybillController.dispose();
    _mpesaTillController.dispose();
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
        // Use residentStatus field - maps isResident boolean to string
        'residentStatus': _isResident ? 'RESIDENT' : 'NON_RESIDENT',
        if (_nssfController.text.isNotEmpty)
          'nssfNumber': _nssfController.text.trim(),
        if (_nhifController.text.isNotEmpty)
          'shifNumber': _nhifController.text.trim(),
        'countryId': _selectedCountryId,
        if (_cityController.text.isNotEmpty) 'city': _cityController.text.trim(),
        if (_businessNameController.text.isNotEmpty)
          'businessName': _businessNameController.text.trim(),
        if (_bankNameController.text.isNotEmpty)
          'bankName': _bankNameController.text.trim(),
        if (_bankAccountController.text.isNotEmpty)
          'bankAccount': _bankAccountController.text.trim(),
        if (_mpesaPhoneController.text.isNotEmpty)
          'phoneNumber': _mpesaPhoneController.text.trim(),
        if (_mpesaPaybillController.text.isNotEmpty)
          'mpesaPaybill': _mpesaPaybillController.text.trim(),
        if (_mpesaTillController.text.isNotEmpty)
          'mpesaTill': _mpesaTillController.text.trim(),
        if (_addressController.text.isNotEmpty)
          'address': _addressController.text.trim(),
        'defaultPayrollFrequency': _payrollFrequency,
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

        // Mark onboarding as completed
        await ref.read(tourProgressProvider.notifier).completeOnboarding();

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
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuart,
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
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
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
      body: Stack(
        children: [
          // Dynamic Abstract Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A), // Dark Slate
                    Color(0xFF1E293B), // Slate
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
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
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
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Column(
                    children: [
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
                    ],
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
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
                  'Finish Customizing',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Complete your profile to get started',
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
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: isCompleted || isCurrent
                              ? const LinearGradient(
                                  colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                                )
                              : null,
                          color: isCompleted || isCurrent 
                              ? null 
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: isCurrent ? [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 0),
                            )
                          ] : null,
                        ),
                      ),
                    ),
                    if (index < _totalSteps - 1) const SizedBox(width: 8),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStepTitle(_currentStep),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Step ${_currentStep + 1}/$_totalSteps',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF93C5FD),
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
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutQuart,
        )),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
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
        ),
      ),
    );
  }

  Widget _buildPersonalDetailsStep() {
    return _buildStepCard(
      children: [
        _buildSectionHeader(
          icon: Icons.person_rounded,
          title: 'Personal Information',
          subtitle: 'Tell us a bit about yourself',
        ),
        const SizedBox(height: 32),
        _buildTextField(
          _firstNameController,
          'First Name',
          'Enter your first name',
          required: true,
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          _lastNameController,
          'Last Name',
          'Enter your last name',
          required: true,
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          _businessNameController,
          'Business Name (Optional)',
          'e.g. Acme Corp',
          icon: Icons.business_rounded,
        ),
      ],
    );
  }

  Widget _buildIdentificationStep(AsyncValue<List<CountryModel>> countriesState) {
    return _buildStepCard(
      children: [
        _buildSectionHeader(
          icon: Icons.badge_rounded,
          title: 'Identification',
          subtitle: 'Verify your identity securely',
        ),
        const SizedBox(height: 32),
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
        const SizedBox(height: 20),
        _buildTextField(
          _idNumberController,
          'ID / Passport Number',
          'Enter your ID number',
          required: true,
          icon: Icons.credit_card_rounded,
        ),
        const SizedBox(height: 20),
        countriesState.when(
          data: (countries) => _buildDropdown(
            value: _selectedNationalityId,
            label: 'Nationality',
            hint: 'Select your nationality',
            icon: Icons.public_rounded,
            items: countries.map((c) => DropdownMenuItem<String>(
              value: c.id,
              child: Text(c.name),
            )).toList(),
            onChanged: (value) => setState(() => _selectedNationalityId = value),
          ),
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          )),
          error: (err, stack) => const Text('Failed to load countries', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildTaxComplianceStep(AsyncValue<List<CountryModel>> countriesState) {
    return _buildStepCard(
      children: [
        _buildSectionHeader(
          icon: Icons.account_balance_rounded,
          title: 'Tax & Compliance',
          subtitle: 'Required for compliant payroll',
        ),
        const SizedBox(height: 32),
        _buildTextField(
          _kraPinController,
          'KRA PIN',
          'e.g., A000000000A',
          required: true,
          icon: Icons.qr_code_rounded,
          helperText: 'Your Kenya Revenue Authority PIN',
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
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
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      color: Color(0xFF60A5FA),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Residency Status',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you a Kenya resident for tax purposes?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildResidencyOption(
                      label: 'Resident',
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
                      label: 'Non-Resident',
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
          const SizedBox(height: 20),
            countriesState.when(
            data: (countries) => _buildDropdown(
              value: _countryOfOrigin,
              label: 'Country of Origin',
              hint: 'Select your country',
              icon: Icons.flag_rounded,
              items: countries.map((c) => DropdownMenuItem<String>(
                value: c.id,
                child: Text(c.name),
              )).toList(),
              onChanged: (value) => setState(() => _countryOfOrigin = value),
            ),
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )),
            error: (err, stack) => const SizedBox(),
          ),
        ],
        const SizedBox(height: 20),
        _buildTextField(
          _nssfController,
          'NSSF Number (Optional)',
          'Enter NSSF number',
          icon: Icons.security_rounded,
          helperText: 'National Social Security Fund',
        ),
        const SizedBox(height: 20),
        _buildTextField(
          _nhifController,
          'SHIF Number (Optional)',
          'Enter SHIF number',
          icon: Icons.medical_services_rounded,
          helperText: 'Social Health Insurance Fund',
        ),
      ],
    );
  }

  Widget _buildLocationStep(AsyncValue<List<CountryModel>> countriesState) {
    return _buildStepCard(
      children: [
        _buildSectionHeader(
          icon: Icons.location_on_rounded,
          title: 'Location & Payment',
          subtitle: 'Where are you based & how to pay?',
        ),
        const SizedBox(height: 32),
        countriesState.when(
          data: (countries) => _buildDropdown(
            value: _selectedCountryId,
            label: 'Country of Residence',
            hint: 'Select your country',
            icon: Icons.public_rounded,
            items: countries.map((c) => DropdownMenuItem<String>(
              value: c.id,
              child: Text(c.name),
            )).toList(),
            onChanged: (value) => setState(() => _selectedCountryId = value),
          ),
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          )),
          error: (err, stack) => const SizedBox(),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          _cityController,
          'City / County (Optional)',
          'e.g., Nairobi',
          icon: Icons.apartment_rounded,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          _addressController,
          'Physical Address (Optional)',
          'Enter your address',
          icon: Icons.home_work_rounded,
          maxLines: 2,
        ),
        const SizedBox(height: 32),
         const Text(
          'Payment Details (Optional)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _bankNameController,
          'Bank Name',
          'e.g. KCB, Equity',
          icon: Icons.account_balance_rounded,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _bankAccountController,
          'Bank Account Number',
          'Enter account number',
          icon: Icons.numbers_rounded,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _mpesaPhoneController,
          'M-Pesa Phone Number',
          'e.g. 0712345678',
          icon: Icons.phone_android_rounded,
          helperText: 'Your M-Pesa registered phone for receiving payments',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _mpesaPaybillController,
                'Paybill (Business)',
                'Paybill No.',
                icon: Icons.payment_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                _mpesaTillController,
                'Till (Business)',
                'Till No.',
                icon: Icons.store_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Payroll Settings Section
        const Text(
          'Payroll Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'How often do you pay your workers?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 16),
        _buildPayrollFrequencySelector(),
      ],
    );
  }

  Widget _buildPayrollFrequencySelector() {
    final frequencies = [
      {'value': 'WEEKLY', 'label': 'Weekly', 'icon': Icons.view_week_rounded},
      {'value': 'BI_WEEKLY', 'label': 'Bi-Weekly', 'icon': Icons.date_range_rounded},
      {'value': 'MONTHLY', 'label': 'Monthly', 'icon': Icons.calendar_month_rounded},
    ];

    return Row(
      children: frequencies.map((freq) {
        final isSelected = _payrollFrequency == freq['value'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _payrollFrequency = freq['value'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : Colors.white.withValues(alpha: 0.1),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      freq['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.white60,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      freq['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? Colors.white : Colors.white60,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Custom text field with premium styling
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool required = false,
    IconData? icon,
    String? helperText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            helperText: helperText,
            helperStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.all(16),
            prefixIcon: icon != null ? Icon(icon, color: Colors.white54) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            errorStyle: const TextStyle(color: Color(0xFFF87171)),
          ),
          validator: (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return '$label is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Custom dropdown with premium styling
  Widget _buildDropdown({
    required String? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(fontSize: 16, color: Colors.white),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.all(16),
            prefixIcon: Icon(icon, color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: _currentStep == 0 ? 1 : 1, // Keep consistant sizing
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                            _currentStep == _totalSteps - 1 ? Icons.check_circle_outline : Icons.arrow_forward_rounded,
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
}
