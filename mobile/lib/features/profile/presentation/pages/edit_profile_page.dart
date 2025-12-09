
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
  final _firstNameCtrl = TextEditingController(); // Read-only or separate update?

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
    _firstNameCtrl.text = '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_loadedProfile == null) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      
      final data = {
        'kraPin': _kraPinCtrl.text,
        'nssfNumber': _nssfCtrl.text,
        'shifNumber': _shifCtrl.text,
        'businessName': _businessNameCtrl.text.isEmpty ? null : _businessNameCtrl.text,
        'bankName': _bankNameCtrl.text.isEmpty ? null : _bankNameCtrl.text,
        'bankAccount': _bankAccountCtrl.text.isEmpty ? null : _bankAccountCtrl.text,
        'mpesaPaybill': _paybillCtrl.text.isEmpty ? null : _paybillCtrl.text,
        'mpesaTill': _tillCtrl.text.isEmpty ? null : _tillCtrl.text,
        
        // Preserve required fields
        'idType': _loadedProfile!.idType,
        'idNumber': _loadedProfile!.idNumber,
        'address': _loadedProfile!.address,
        'city': _loadedProfile!.city,
        'countryId': _loadedProfile!.countryId,
        'nationalityId': _loadedProfile!.nationalityId,
      };
      
      // Update: I'll need to fetch the profile again or use state to get missing required fields 
      // like idType/idNumber/address/city/countryId.
      // But for this immediate task, I assume the user HAS these set (from onboarding) 
      // and I just need to add the new ones.
      // I'll implement a merge logic or assume backend allows partial update if I change DTO to Optional?
      // I changed the NEW fields to Optional. The OLD fields are still Required.
      // So I MUST send the old fields back.
      
      // I'll handle this by storing the fetched profile and merging.
      
      // ... implementation detail ...
      await repo.updateComplianceProfile(data); // This will fail if I don't provide idType etc.

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
            const SizedBox(height: 16),
            
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
