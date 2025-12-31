import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Domain imports - adjust paths as needed
import '../../auth/presentation/providers/auth_provider.dart';
import '../../subscriptions/presentation/providers/subscription_provider.dart';
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

  // ===========================================================================
  // PREFERENCES SECTION
  // ===========================================================================

  List<SettingItem> _buildPreferencesItems(BuildContext context, WidgetRef ref) {
    return [
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
      SettingItem(
        icon: Icons.home_outlined,
        title: 'Default Property',
        subtitle: settings.defaultPropertyId != null
            ? 'Property selected'
            : 'Not configured',
        onTap: () => context.push(SettingsRoutes.properties),
      ),
    ];
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
    final bankNameController = TextEditingController(text: settings.bankName ?? '');
    final accountController = TextEditingController(text: settings.bankAccount ?? '');

    SettingsBottomSheet.show(
      context: context,
      title: 'Bank Account',
      isScrollControlled: true,
      child: FormBottomSheet(
        title: 'Bank Account',
        fields: [
          SettingsTextField(
            controller: bankNameController,
            label: 'Bank Name',
            hint: 'e.g., Equity Bank',
          ),
          const SizedBox(height: 16),
          SettingsTextField(
            controller: accountController,
            label: 'Account Number',
            hint: '0123456789',
            keyboardType: TextInputType.number,
          ),
        ],
        submitLabel: 'Save',
        onSubmit: () {
          ref.read(settingsProvider.notifier).updateBankAccount(
                bankNameController.text,
                accountController.text,
              );
          _showSavedSnackbar(context, 'Bank account saved');
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
}
