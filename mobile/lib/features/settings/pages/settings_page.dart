import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

// Domain imports - adjust paths as needed
import '../../auth/presentation/providers/auth_provider.dart';
import '../../subscriptions/presentation/providers/subscription_provider.dart';
import '../../properties/data/models/property_model.dart';
import '../../properties/presentation/providers/properties_provider.dart';
import '../../workers/presentation/providers/workers_provider.dart';
import '../providers/settings_provider.dart';

// Local imports
import '../constants/settings_constants.dart';
import '../models/setting_item.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/settings_bottom_sheets.dart';
import '../widgets/settings_dialogs.dart';

/// Settings page with organized sections
///
/// Allows users to configure:
/// - Profile and account
/// - App preferences (theme, defaults)
/// - Payment settings (bank, M-Pesa)
/// - Quick access to features
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(userSubscriptionProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: SettingsTheme.backgroundColor(context),
      appBar: _buildAppBar(context),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, error),
        data: (settings) {
          final tier = _extractTier(subscriptionAsync);
          
          return _SettingsContent(
            settings: settings,
            tier: tier,
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text('Settings'),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: 'Help',
          onPressed: () => _showHelpSnackbar(context),
        ),
      ],
    );
  }

  void _showHelpSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configure your app preferences and payment settings'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Failed to load settings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _extractTier(AsyncValue<dynamic> subscriptionAsync) {
    return subscriptionAsync.when(
      data: (sub) => sub?.plan.tier ?? 'FREE',
      loading: () => 'Loading...',
      error: (_, _) => 'FREE',
    );
  }
}

/// Settings content with all sections
class _SettingsContent extends ConsumerWidget {
  final UserSettings settings;
  final String tier;

  const _SettingsContent({
    required this.settings,
    required this.tier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          ProfileCard(
            tier: tier,
            onEditTap: () => context.push(SettingsRoutes.profileEdit),
            photoUrl: settings.photoUrl,
            onAvatarTap: () => _pickAndUploadPhoto(context, ref),
          ),

          // Quick access grid
          const SettingsSectionLabel('QUICK ACCESS'),
          QuickAccessGrid(
            items: QuickAccessItems.defaults,
            onItemTap: (route) => context.push(route),
          ),

          // Preferences
          const SettingsSectionLabel('PREFERENCES'),
          SettingsCard(
            items: _buildPreferencesItems(context, ref),
          ),

          // Payment
          const SettingsSectionLabel('PAYMENT & BILLING'),
          SettingsCard(
            items: _buildPaymentItems(context, ref),
          ),

          // Account
          const SettingsSectionLabel('ACCOUNT'),
          SettingsCard(
            items: _buildAccountItems(context, ref),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                   Text(
                    'Photo Guidelines',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ideal size: 1024 x 1024 px (1:1 ratio)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    if (!context.mounted) return;

    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedFile == null) return;

    try {
      final bytes = await pickedFile.readAsBytes();
      if (!context.mounted) return;
      
      await ref.read(settingsProvider.notifier).uploadProfilePhoto(
        bytes, 
        pickedFile.name,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  // ===========================================================================
  // PREFERENCES SECTION
  // ===========================================================================

  List<SettingItem> _buildPreferencesItems(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(userSubscriptionProvider);
    final isPlatinum = subscriptionAsync.when(
      data: (sub) => sub?.plan.tier == 'PLATINUM',
      loading: () => false,
      error: (_, __) => false,
    );

    final items = <SettingItem>[
      SettingItem(
        icon: Icons.dark_mode_outlined,
        title: 'Dark Mode',
        subtitle: settings.themeMode == ThemeMode.dark ? 'Enabled' : 'Disabled',
        trailing: Switch(
          value: settings.themeMode == ThemeMode.dark,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).updateThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
          },
        ),
      ),
      SettingItem(
        icon: Icons.schedule_outlined,
        title: 'Default Pay Frequency',
        subtitle: FrequencyLabels.format(settings.defaultPayrollFrequency),
        onTap: () => _showFrequencyPicker(context, ref),
      ),
      SettingItem(
        icon: Icons.work_outline,
        title: 'Default Employment Type',
        subtitle: EmploymentTypeLabels.format(settings.defaultEmploymentType),
        onTap: () => _showEmploymentTypePicker(context, ref),
      ),
    ];

    // Only show property setting for PLATINUM users
    if (isPlatinum) {
      items.add(_buildDefaultPropertyItem(context, ref));
    }

    return items;
  }

  void _showFrequencyPicker(BuildContext context, WidgetRef ref) {
    RadioPickerSheet.show<String>(
      context: context,
      title: 'Select Pay Frequency',
      currentValue: settings.defaultPayrollFrequency,
      options: FrequencyLabels.labels,
      onSelected: (value) {
        ref.read(settingsProvider.notifier).updateDefaultFrequency(value);
      },
    );
  }

  void _showEmploymentTypePicker(BuildContext context, WidgetRef ref) {
    RadioPickerSheet.show<String>(
      context: context,
      title: 'Default Employment Type',
      currentValue: settings.defaultEmploymentType,
      options: EmploymentTypeLabels.labels,
      onSelected: (value) {
        ref.read(settingsProvider.notifier).updateDefaultEmploymentType(value);
      },
    );
  }

  // ===========================================================================
  // PAYMENT SECTION
  // ===========================================================================

  List<SettingItem> _buildPaymentItems(BuildContext context, WidgetRef ref) {
    return [
      SettingItem(
        icon: Icons.account_balance_outlined,
        title: 'Bank Account',
        subtitle: settings.bankName ?? 'Not configured',
        onTap: () => _showBankAccountEditor(context, ref),
      ),
      SettingItem(
        icon: Icons.phone_android_outlined,
        title: 'M-Pesa Settings',
        subtitle: settings.mpesaPhone ?? 'Not configured',
        onTap: () => _showMpesaEditor(context, ref),
      ),
      SettingItem(
        icon: Icons.payment_outlined,
        title: 'Default Payment Method',
        subtitle: PaymentMethodLabels.format(settings.defaultPaymentMethod),
        onTap: () => _showPaymentMethodPicker(context, ref),
      ),
    ];
  }

  void _showBankAccountEditor(BuildContext context, WidgetRef ref) {
    final accountController = TextEditingController(text: settings.bankAccount ?? '');
    String? selectedBankCode = settings.bankCode;
    String? selectedBankName = settings.bankName;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final banksAsync = ref.watch(supportedBanksProvider);
          
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bank Account',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Bank Dropdown
                banksAsync.when(
                  data: (banks) {
                    // Try to find current bank by code or name
                    if (selectedBankCode == null && selectedBankName != null) {
                      final matchedBank = banks.firstWhere(
                        (b) => b['bank_name']?.toString().toLowerCase() == selectedBankName?.toLowerCase(),
                        orElse: () => {},
                      );
                      if (matchedBank.isNotEmpty) {
                        selectedBankCode = matchedBank['bank_code']?.toString();
                      }
                    }
                    
                    return DropdownButtonFormField<String>(
                      initialValue: selectedBankCode != null && banks.any((b) => b['bank_code'].toString() == selectedBankCode)
                          ? selectedBankCode
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Bank Name',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      hint: const Text('Select Bank'),
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
                          final bank = banks.firstWhere(
                            (b) => b['bank_code'].toString() == val,
                            orElse: () => {},
                          );
                          setModalState(() {
                            selectedBankCode = val;
                            selectedBankName = bank['bank_name']?.toString();
                          });
                        }
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading banks: $e', style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 16),
                
                // Account Number
                TextFormField(
                  controller: accountController,
                  decoration: const InputDecoration(
                    labelText: 'Account Number',
                    hintText: '0123456789',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedBankName != null && selectedBankName!.isNotEmpty) {
                        ref.read(settingsProvider.notifier).updateBankAccount(
                          selectedBankName!,
                          selectedBankCode,
                          accountController.text,
                        );
                        Navigator.pop(ctx);
                        _showSavedSnackbar(context, 'Bank account saved');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a bank')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMpesaEditor(BuildContext context, WidgetRef ref) {
    final phoneController = TextEditingController(text: settings.mpesaPhone ?? '');
    final paybillController = TextEditingController(text: settings.mpesaPaybill ?? '');

    SettingsBottomSheet.show(
      context: context,
      title: 'M-Pesa Settings',
      isScrollControlled: true,
      child: FormBottomSheet(
        title: 'M-Pesa Settings',
        fields: [
          SettingsTextField(
            controller: phoneController,
            label: 'Phone Number',
            hint: '0712345678',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          SettingsTextField(
            controller: paybillController,
            label: 'Paybill (Optional)',
            hint: 'e.g., 247247',
            prefixIcon: Icons.account_balance_wallet,
            keyboardType: TextInputType.number,
          ),
        ],
        submitLabel: 'Save',
        onSubmit: () {
          ref.read(settingsProvider.notifier).updateMpesaSettings(
                paybillController.text.isEmpty ? null : paybillController.text,
                null,
                phoneController.text.isEmpty ? null : phoneController.text,
              );
          _showSavedSnackbar(context, 'M-Pesa settings saved');
        },
      ),
    );
  }

  void _showPaymentMethodPicker(BuildContext context, WidgetRef ref) {
    RadioPickerSheet.show<String>(
      context: context,
      title: 'Default Payment Method',
      currentValue: settings.defaultPaymentMethod,
      options: PaymentMethodLabels.labels,
      onSelected: (value) {
        ref.read(settingsProvider.notifier).updateDefaultPaymentMethod(value);
      },
    );
  }

  // ===========================================================================
  // ACCOUNT SECTION
  // ===========================================================================

  List<SettingItem> _buildAccountItems(BuildContext context, WidgetRef ref) {
    return [
      SettingItem(
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        subtitle: 'Push, email & SMS alerts',
        onTap: () => _showComingSoon(context, 'Notification settings'),
      ),
      SettingItem(
        icon: Icons.help_outline,
        title: 'Help & Support',
        subtitle: 'FAQs, guides & contact us',
        onTap: () => _showComingSoon(context, 'Help & Support'),
      ),
      SettingItem(
        icon: Icons.info_outline,
        title: 'About',
        subtitle: 'Version ${AppInfo.version}',
        onTap: () => AboutAppDialog.show(context),
      ),
      SettingItem(
        icon: Icons.logout,
        title: 'Logout',
        subtitle: 'Sign out of your account',
        iconColor: SettingsTheme.dangerColor,
        titleColor: SettingsTheme.dangerColor,
        onTap: () => _handleLogout(context, ref),
      ),
    ];
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await LogoutConfirmDialog.show(context);

    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) {
        context.go(SettingsRoutes.login);
      }
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  void _showSavedSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===========================================================================
  // PROPERTY PICKER
  // ===========================================================================

  void _showPropertyPicker(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);
    
    propertiesAsync.when(
      data: (properties) {
        if (properties.isEmpty) {
          // No properties - navigate to add property
          _showNoPropertiesDialog(context);
          return;
        }
        
        if (properties.length == 1) {
          // Single property - auto-select it
          ref.read(settingsProvider.notifier).updateDefaultProperty(properties.first.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Default property set to: ${properties.first.name}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        
        // Multiple properties - show picker
        _showPropertySelectionSheet(context, ref, properties);
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading properties...')),
        );
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading properties: $error')),
        );
      },
    );
  }

  void _showNoPropertiesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No Properties'),
        content: const Text('You need to add a property first to set it as default.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/properties/add');
            },
            child: const Text('Add Property'),
          ),
        ],
      ),
    );
  }

  void _showPropertySelectionSheet(
    BuildContext context, 
    WidgetRef ref, 
    List<PropertyModel> properties
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Default Property',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...properties.map((property) {
                final isSelected = property.id == settings.defaultPropertyId;
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.home_work,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  title: Text(
                    property.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    property.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: isSelected 
                      ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                      : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                  onTap: () {
                    ref.read(settingsProvider.notifier).updateDefaultProperty(property.id);
                    Navigator.pop(ctx);
                    _showSavedSnackbar(context, 'Default property updated');
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
  SettingItem _buildDefaultPropertyItem(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);
    
    return SettingItem(
      icon: Icons.home_outlined,
      title: 'Default Property',
      subtitle: _getSubtitle(propertiesAsync),
      trailing: propertiesAsync.when(
        data: (properties) {
          if (properties.length > 1) {
            return const Icon(Icons.chevron_right, color: Colors.grey);
          }
          return null;
        },
        loading: () => const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, __) => const Icon(Icons.error_outline, color: Colors.red),
      ),
      onTap: () => _showPropertyPicker(context, ref),
    );
  }

  String _getSubtitle(AsyncValue<List<PropertyModel>> propertiesAsync) {
    return propertiesAsync.when(
      data: (properties) {
        if (properties.isEmpty) {
          return 'No properties - tap to add';
        }
        if (settings.defaultPropertyId == null) {
          if (properties.length == 1) {
            return 'Auto-set to: ${properties.first.name}';
          }
          return 'Tap to select';
        }
        
        // Find the selected property
        final selectedProperty = properties.firstWhere(
          (p) => p.id == settings.defaultPropertyId,
          orElse: () => properties.first,
        );
        return selectedProperty.name;
      },
      loading: () => 'Loading...',
      error: (_, __) => 'Error loading',
    );
  }
}


