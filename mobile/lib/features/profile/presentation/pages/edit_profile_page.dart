
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/models/profile_model.dart';

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
  final _nationalityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _residentStatusCtrl = TextEditingController();

  ProfileModel? _loadedProfile;

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
    _bankAccountCtrl.text = p.bankAccount ?? '';
    _paybillCtrl.text = p.mpesaPaybill ?? '';
    _tillCtrl.text = p.mpesaTill ?? '';
    _firstNameCtrl.text = p.firstName ?? '';
    _lastNameCtrl.text = p.lastName ?? '';
    _emailCtrl.text = p.email;
    _phoneCtrl.text = p.phoneNumber ?? '';
    
    _idTypeCtrl.text = p.idType ?? '';
    _idNumberCtrl.text = p.idNumber ?? '';
    _nationalityCtrl.text = p.nationalityId ?? '';
    _addressCtrl.text = p.address ?? '';
    _cityCtrl.text = p.city ?? '';
    _countryCtrl.text = p.countryId ?? '';
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
        'nationalityId': _nationalityCtrl.text.isEmpty ? null : _nationalityCtrl.text,
        'address': _addressCtrl.text.isEmpty ? null : _addressCtrl.text,
        'city': _cityCtrl.text.isEmpty ? null : _cityCtrl.text,
        'countryId': _countryCtrl.text.isEmpty ? null : _countryCtrl.text,
        'residentStatus': _residentStatusCtrl.text.isEmpty ? null : _residentStatusCtrl.text,

        'kraPin': _kraPinCtrl.text,
        'nssfNumber': _nssfCtrl.text,
        'shifNumber': _shifCtrl.text,
        'businessName': _businessNameCtrl.text.isEmpty ? null : _businessNameCtrl.text,
        'bankName': _bankNameCtrl.text.isEmpty ? null : _bankNameCtrl.text,
        'bankAccount': _bankAccountCtrl.text.isEmpty ? null : _bankAccountCtrl.text,
        'mpesaPaybill': _paybillCtrl.text.isEmpty ? null : _paybillCtrl.text,
        'mpesaTill': _tillCtrl.text.isEmpty ? null : _tillCtrl.text,
      };
      
      await repo.updateComplianceProfile(data);

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
            TextFormField(
              controller: _nationalityCtrl,
              decoration: const InputDecoration(labelText: 'Nationality (ID)'),
            ),
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
                  child: TextFormField(
                    controller: _countryCtrl,
                    decoration: const InputDecoration(labelText: 'Country (ID)'),
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
            TextFormField(
              controller: _bankNameCtrl,
              decoration: const InputDecoration(labelText: 'Bank Name'),
            ),
            TextFormField(
              controller: _bankAccountCtrl,
              decoration: const InputDecoration(labelText: 'Account Number'),
            ),
            const SizedBox(height: 16),
            
            _buildSectionHeader('M-Pesa Details (Optional)'),
            TextFormField(
              controller: _paybillCtrl,
              decoration: const InputDecoration(labelText: 'Paybill Number'),
            ),
            TextFormField(
              controller: _tillCtrl,
              decoration: const InputDecoration(labelText: 'Till Number'),
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
}
