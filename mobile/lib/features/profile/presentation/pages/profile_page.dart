import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading profile: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(profileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) {
          // Extract values for null-safe access
          final firstName = profile.firstName ?? '';
          final lastName = profile.lastName ?? '';
          final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
          final fullName = '$firstName $lastName'.trim();
          final email = profile.email;
          final phone = profile.phoneNumber ?? profile.mpesaPhone ?? 'Not set';
          final bankName = profile.bankName ?? '';
          final bankAccount = profile.bankAccount ?? 'No account';
          final mpesaPhone = profile.mpesaPhone ?? '';
          final businessName = profile.businessName ?? '';
          
          final hasBankDetails = bankName.isNotEmpty;
          final hasMpesa = mpesaPhone.isNotEmpty;
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  initials.isEmpty ? '?' : initials,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                fullName.isEmpty ? 'User' : fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              // Email Card
              Card(
                child: ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(email),
                ),
              ),
              const SizedBox(height: 8),
              
              // Phone Card
              Card(
                child: ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Phone'),
                  subtitle: Text(phone),
                ),
              ),
              const SizedBox(height: 8),
              
              // Bank Details Card
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance),
                  title: const Text('Bank Details'),
                  subtitle: Text(
                    hasBankDetails
                        ? '$bankName - $bankAccount'
                        : 'Not configured',
                  ),
                  trailing: Icon(
                    hasBankDetails ? Icons.check_circle : Icons.warning_amber,
                    color: hasBankDetails ? Colors.green : Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // M-Pesa Card
              Card(
                child: ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: const Text('M-Pesa Phone'),
                  subtitle: Text(hasMpesa ? mpesaPhone : 'Not configured'),
                  trailing: Icon(
                    hasMpesa ? Icons.check_circle : Icons.warning_amber,
                    color: hasMpesa ? Colors.green : Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Business Details
              if (businessName.isNotEmpty)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.business),
                    title: const Text('Business Name'),
                    subtitle: Text(businessName),
                  ),
                ),
              const SizedBox(height: 24),
              
              const Text(
                'Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/profile/edit');
                  },
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification settings coming soon')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help & Support coming soon')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
