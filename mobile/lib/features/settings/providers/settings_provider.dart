import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_service.dart';

/// User settings model
class UserSettings {
  final String? bankName;
  final String? bankAccount;
  final String? mpesaPaybill;
  final String? mpesaTill;
  final String? mpesaPhone;
  final String defaultPaymentMethod;
  final String defaultPayrollFrequency;
  final String defaultEmploymentType;
  final String? defaultPropertyId;
  final ThemeMode themeMode;

  UserSettings({
    this.bankName,
    this.bankAccount,
    this.mpesaPaybill,
    this.mpesaTill,
    this.mpesaPhone,
    this.defaultPaymentMethod = 'MPESA',
    this.defaultPayrollFrequency = 'MONTHLY',
    this.defaultEmploymentType = 'FIXED',
    this.defaultPropertyId,
    this.themeMode = ThemeMode.light,
  });

  UserSettings copyWith({
    String? bankName,
    String? bankAccount,
    String? mpesaPaybill,
    String? mpesaTill,
    String? mpesaPhone,
    String? defaultPaymentMethod,
    String? defaultPayrollFrequency,
    String? defaultEmploymentType,
    String? defaultPropertyId,
    ThemeMode? themeMode,
  }) {
    return UserSettings(
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      mpesaPaybill: mpesaPaybill ?? this.mpesaPaybill,
      mpesaTill: mpesaTill ?? this.mpesaTill,
      mpesaPhone: mpesaPhone ?? this.mpesaPhone,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      defaultPayrollFrequency: defaultPayrollFrequency ?? this.defaultPayrollFrequency,
      defaultEmploymentType: defaultEmploymentType ?? this.defaultEmploymentType,
      defaultPropertyId: defaultPropertyId ?? this.defaultPropertyId,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      bankName: json['bankName'],
      bankAccount: json['bankAccount'],
      mpesaPaybill: json['mpesaPaybill'],
      mpesaTill: json['mpesaTill'],
      mpesaPhone: json['mpesaPhone'],
      defaultPaymentMethod: json['defaultPaymentMethod'] ?? 'MPESA',
      defaultPayrollFrequency: json['defaultPayrollFrequency'] ?? 'MONTHLY',
      defaultEmploymentType: json['defaultEmploymentType'] ?? 'FIXED',
      defaultPropertyId: json['defaultPropertyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'bankAccount': bankAccount,
      'mpesaPaybill': mpesaPaybill,
      'mpesaTill': mpesaTill,
      'mpesaPhone': mpesaPhone,
      'defaultPaymentMethod': defaultPaymentMethod,
      'defaultPayrollFrequency': defaultPayrollFrequency,
      'defaultEmploymentType': defaultEmploymentType,
      'defaultPropertyId': defaultPropertyId,
    };
  }
}

/// Settings notifier using AsyncNotifier pattern
class SettingsNotifier extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() async {
    return _loadSettings();
  }

  Future<UserSettings> _loadSettings() async {
    // Load theme from local storage first
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('themeMode') ?? 0;
    final themeMode = ThemeMode.values[themeModeIndex];

    // Try to load settings from API
    try {
      final response = await ApiService().get('/users/profile');
      if (response.statusCode == 200) {
        return UserSettings.fromJson(response.data).copyWith(
          themeMode: themeMode,
        );
      }
    } catch (apiError) {
      // API failed, use defaults
      debugPrint('Failed to load settings: $apiError');
    }

    // Fallback to defaults
    return UserSettings(themeMode: themeMode);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadSettings());
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final current = state.value ?? UserSettings();
    state = AsyncValue.data(current.copyWith(themeMode: mode));

    // Persist to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  Future<void> updateBankAccount(String bankName, String accountNumber) async {
    final current = state.value ?? UserSettings();
    state = AsyncValue.data(current.copyWith(
      bankName: bankName,
      bankAccount: accountNumber,
    ));

    // Persist to API
    await _saveToApi({
      'bankName': bankName,
      'bankAccount': accountNumber,
    });
  }

  Future<void> updateMpesaSettings(String? paybill, String? till, String? phone) async {
    final current = state.value ?? UserSettings();
    state = AsyncValue.data(current.copyWith(
      mpesaPaybill: paybill,
      mpesaTill: till,
      mpesaPhone: phone,
    ));

    await _saveToApi({
      'mpesaPaybill': paybill,
      'mpesaTill': till,
      'mpesaPhone': phone,
    });
  }

  Future<void> updateDefaultPaymentMethod(String method) async {
    final current = state.value ?? UserSettings();
    state = AsyncValue.data(current.copyWith(defaultPaymentMethod: method));

    await _saveToApi({'defaultPaymentMethod': method});
  }

  Future<void> updateDefaultFrequency(String frequency) async {
    final current = state.value ?? UserSettings();
    state = AsyncValue.data(current.copyWith(defaultPayrollFrequency: frequency));

    await _saveToApi({'defaultPayrollFrequency': frequency});
  }

  Future<void> updateDefaultEmploymentType(String type) async {
    final current = state.value ?? UserSettings();
    state = AsyncValue.data(current.copyWith(defaultEmploymentType: type));

    await _saveToApi({'defaultEmploymentType': type});
  }

  Future<void> updateDefaultProperty(String? propertyId) async {
    final current = state.value ?? UserSettings();
    state = AsyncValue.data(current.copyWith(defaultPropertyId: propertyId));

    await _saveToApi({'defaultPropertyId': propertyId});
  }

  Future<void> _saveToApi(Map<String, dynamic> updates) async {
    try {
      await ApiService().patch('/users/profile', data: updates);
    } catch (e) {
      // Silently fail - settings are still in local state
      debugPrint('Failed to save settings to API: $e');
    }
  }
}

/// Settings provider
final settingsProvider = AsyncNotifierProvider<SettingsNotifier, UserSettings>(() {
  return SettingsNotifier();
});

/// Theme mode provider (convenience accessor)
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).when(
    data: (settings) => settings.themeMode,
    loading: () => ThemeMode.light,
    error: (_, _) => ThemeMode.light,
  );
});
