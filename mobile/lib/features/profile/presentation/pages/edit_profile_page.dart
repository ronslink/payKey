import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/models/profile_model.dart';
import '../../../onboarding/presentation/providers/countries_provider.dart';
import '../../../workers/presentation/providers/workers_provider.dart';
import '../../../settings/providers/settings_provider.dart';
import '../providers/profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  final _businessNameCtrl = TextEditingController();
  final _kraPinCtrl = TextEditingController();
  final _nssfCtrl = TextEditingController();
  final _shifCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankCodeCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  final _paybillCtrl = TextEditingController();
  final _tillCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Identity & Location
  final _idTypeCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _residentStatusCtrl = TextEditingController();
  // M-Pesa Phone for direct payments
  final _mpesaPhoneCtrl = TextEditingController();

  ProfileModel? _loadedProfile;
  String? _selectedCountryId;
  String? _selectedNationalityId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      final profile = await repo.getProfile();
      _loadedProfile = profile;
      _populateFields(profile);
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  void _populateFields(ProfileModel p) {
    _businessNameCtrl.text = p.businessName ?? '';
    _kraPinCtrl.text = p.kraPin ?? '';
    _nssfCtrl.text = p.nssfNumber ?? '';
    _shifCtrl.text = p.shifNumber ?? '';
    _bankNameCtrl.text = p.bankName ?? '';
    _bankCodeCtrl.text = p.bankCode ?? '';
    _bankAccountCtrl.text = p.bankAccount ?? '';
    _paybillCtrl.text = p.mpesaPaybill ?? '';
    _tillCtrl.text = p.mpesaTill ?? '';
    _firstNameCtrl.text = p.firstName ?? '';
    _lastNameCtrl.text = p.lastName ?? '';
    _emailCtrl.text = p.email;
    _phoneCtrl.text = p.phoneNumber ?? '';
    _mpesaPhoneCtrl.text = p.mpesaPhone ?? '';
    
    _idTypeCtrl.text = p.idType ?? '';
    _idNumberCtrl.text = p.idNumber ?? '';
    _selectedNationalityId = p.nationalityId;
    _addressCtrl.text = p.address ?? '';
    _cityCtrl.text = p.city ?? '';
    _selectedCountryId = p.countryId;
    _residentStatusCtrl.text = p.residentStatus ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_loadedProfile == null) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      
      final data = {
        'firstName': _firstNameCtrl.text,
        'lastName': _lastNameCtrl.text,
        'email': _emailCtrl.text,
        'phoneNumber': _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
        
        'idType': _idTypeCtrl.text,
        'idNumber': _idNumberCtrl.text,
        'nationalityId': _selectedNationalityId,
        'address': _addressCtrl.text.isEmpty ? null : _addressCtrl.text,
        'city': _cityCtrl.text.isEmpty ? null : _cityCtrl.text,
        'countryId': _selectedCountryId,
        'residentStatus': _residentStatusCtrl.text.isEmpty ? null : _residentStatusCtrl.text,

        'kraPin': _kraPinCtrl.text,
        'nssfNumber': _nssfCtrl.text,
        'shifNumber': _shifCtrl.text,
        'businessName': _businessNameCtrl.text.isEmpty ? null : _businessNameCtrl.text,
        'bankName': _bankNameCtrl.text.isEmpty ? null : _bankNameCtrl.text,
        'bankCode': _bankCodeCtrl.text.isEmpty ? null : _bankCodeCtrl.text,
        'bankAccount': _bankAccountCtrl.text.isEmpty ? null : _bankAccountCtrl.text,
        'mpesaPaybill': _paybillCtrl.text.isEmpty ? null : _paybillCtrl.text,
        'mpesaTill': _tillCtrl.text.isEmpty ? null : _tillCtrl.text,
        'mpesaPhone': _mpesaPhoneCtrl.text.isEmpty ? null : _mpesaPhoneCtrl.text,
      };
      
      await repo.updateComplianceProfile(data);
      
      // Force refresh of both profile and settings providers so other screens update
      ref.invalidate(profileProvider);
      ref.invalidate(settingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Compliance Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Business Details'),
            TextFormField(
              controller: _businessNameCtrl,
              decoration: const InputDecoration(labelText: 'Business Name (Optional)'),
            ),
            _buildSectionHeader('Personal Details'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameCtrl,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameCtrl,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email Address'),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number (Optional)'),
              keyboardType: TextInputType.phone,
            ),
            
            _buildSectionHeader('Identity Details'),
            // TODO: Use Dropdowns for ID Type/Nationality if list available
            TextFormField(
              controller: _idTypeCtrl,
              decoration: const InputDecoration(labelText: 'ID Type (e.g., NATIONAL_ID, PASSPORT)'),
               // validator: (v) => v?.isEmpty == true ? 'Required' : null, 
            ),
            TextFormField(
              controller: _idNumberCtrl,
              decoration: const InputDecoration(labelText: 'ID Number'),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildCountryDropdown(
              label: 'Nationality',
              value: _selectedNationalityId,
              onChanged: (v) => setState(() => _selectedNationalityId = v),
            ),
            const SizedBox(height: 16),
             TextFormField(
              controller: _residentStatusCtrl,
              decoration: const InputDecoration(labelText: 'Resident Status'),
            ),

            _buildSectionHeader('Location Details'),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCountryDropdown(
                    label: 'Country',
                    value: _selectedCountryId,
                    onChanged: (v) => setState(() => _selectedCountryId = v),
                  ),
                ),
              ],
            ),

            _buildSectionHeader('Statutory IDs'),
            TextFormField(
              controller: _kraPinCtrl,
              decoration: const InputDecoration(labelText: 'KRA PIN'),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            TextFormField(
              controller: _nssfCtrl,
              decoration: const InputDecoration(labelText: 'NSSF Number'),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            TextFormField(
              controller: _shifCtrl,
              decoration: const InputDecoration(labelText: 'SHIF Number'),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            _buildSectionHeader('Bank Details (Optional)'),
            Consumer(
              builder: (context, ref, child) {
                final banksAsync = ref.watch(supportedBanksProvider);
                print('[EditProfilePage] banksAsync state: $banksAsync');
                return banksAsync.when(
                  data: (banks) {
                    print('[EditProfilePage] Banks loaded: ${banks.length} items');
                    if (banks.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('No banks available. Please check your connection.',
                            style: TextStyle(color: Colors.orange)),
                      );
                    }
                    
                    // Try to match by bankCode first, then fallback to bankName
                    String? selectedCode;
                    final currentCode = _bankCodeCtrl.text;
                    final currentName = _bankNameCtrl.text;
                    bool hasUnmatchedBank = false;
                    
                    if (currentCode.isNotEmpty && 
                        banks.any((b) => b['bank_code'].toString() == currentCode)) {
                      selectedCode = currentCode;
                    } else if (currentName.isNotEmpty) {
                      // Fallback: find bank by name
                      final matchedBank = banks.firstWhere(
                        (b) => b['bank_name']?.toString().toLowerCase() == currentName.toLowerCase(),
                        orElse: () => {},
                      );
                      if (matchedBank.isNotEmpty) {
                        selectedCode = matchedBank['bank_code']?.toString();
                        // Also update the bankCode controller so save works correctly
                        if (selectedCode != null && _bankCodeCtrl.text != selectedCode) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => _bankCodeCtrl.text = selectedCode!);
                            }
                          });
                        }
                      } else {
                        // Bank name is set but doesn't match any supported bank
                        hasUnmatchedBank = true;
                      }
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show warning if saved bank doesn't match
                        if (hasUnmatchedBank) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Current bank "$currentName" not found. Please select from the list below.',
                                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        DropdownButtonFormField<String>(
                          key: ValueKey('bank_${selectedCode ?? 'none'}'),
                          initialValue: selectedCode,
                          decoration: const InputDecoration(labelText: 'Bank Name'),
                          isExpanded: true,
                          items: banks.map((b) {
                            return DropdownMenuItem<String>(
                              value: b['bank_code'].toString(),
                              child: Text(
                                b['bank_name']?.toString() ?? 'Unknown Bank',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _bankCodeCtrl.text = val;
                                final bank = banks.firstWhere(
                                  (b) => b['bank_code'].toString() == val,
                                  orElse: () => {},
                                );
                                _bankNameCtrl.text = bank['bank_name']?.toString() ?? '';
                              });
                            }
                          },
                          hint: const Text('Select Bank'),
                        ),
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading banks: $e', 
                      style: const TextStyle(color: Colors.red)),
                );
              },
            ),
            TextFormField(
              controller: _bankAccountCtrl,
              decoration: const InputDecoration(labelText: 'Account Number'),
            ),
            const SizedBox(height: 16),
            
            _buildSectionHeader('M-Pesa Details (Optional)'),
            TextFormField(
              controller: _mpesaPhoneCtrl,
              decoration: const InputDecoration(
                labelText: 'M-Pesa Phone Number',
                hintText: '0712345678',
                prefixIcon: Icon(Icons.phone_android),
              ),
              keyboardType: TextInputType.phone,
            ),
            TextFormField(
              controller: _paybillCtrl,
              decoration: const InputDecoration(labelText: 'Paybill Number (Optional)'),
            ),
            TextFormField(
              controller: _tillCtrl,
              decoration: const InputDecoration(labelText: 'Till Number (Optional)'),
            ),
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving ? const CircularProgressIndicator() : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

  Widget _buildCountryDropdown({
    required String label,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    final countriesAsync = ref.watch(countriesProvider);
    
    return countriesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error loading countries: $e'),
      data: (countries) {
        // Check if selected value exists in items, otherwise set to null
        final validValue = countries.any((c) => c.id == value) ? value : null;
        
        return DropdownButtonFormField<String>(
          // Using key to force rebuild when value changes  
          key: ValueKey('${label}_$validValue'),
          initialValue: validValue,
          decoration: InputDecoration(labelText: label),
          isExpanded: true,
          items: countries.map((country) {
            return DropdownMenuItem<String>(
              value: country.id,
              child: Text(country.name),
            );
          }).toList(),
          onChanged: onChanged,
          hint: Text('Select $label'),
        );
      },
    );
  }
}
