import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_service.dart';
import '../../profile/presentation/providers/profile_provider.dart';

/// User settings model
class UserSettings {
  final String? bankName;
  final String? bankCode;
  final String? bankAccount;
  final String? mpesaPaybill;
  final String? mpesaTill;
  final String? mpesaPhone;
  final String defaultPaymentMethod;
  final String defaultPayrollFrequency;
  final String defaultEmploymentType;
  final String? defaultPropertyId;
  final String? photoUrl;
  final ThemeMode themeMode;

  UserSettings({
    this.bankName,
    this.bankCode,
    this.bankAccount,
    this.mpesaPaybill,
    this.mpesaTill,
    this.mpesaPhone,
    this.defaultPaymentMethod = 'MPESA',
    this.defaultPayrollFrequency = 'MONTHLY',
    this.defaultEmploymentType = 'FIXED',
    this.defaultPropertyId,
    this.photoUrl,
    this.themeMode = ThemeMode.light,
  });

  UserSettings copyWith({
    String? bankName,
    String? bankCode,
    String? bankAccount,
    String? mpesaPaybill,
    String? mpesaTill,
    String? mpesaPhone,
    String? defaultPaymentMethod,
    String? defaultPayrollFrequency,
    String? defaultEmploymentType,
    String? defaultPropertyId,
    String? photoUrl,
    ThemeMode? themeMode,
  }) {
    return UserSettings(
      bankName: bankName ?? this.bankName,
      bankCode: bankCode ?? this.bankCode,
      bankAccount: bankAccount ?? this.bankAccount,
      mpesaPaybill: mpesaPaybill ?? this.mpesaPaybill,
      mpesaTill: mpesaTill ?? this.mpesaTill,
      mpesaPhone: mpesaPhone ?? this.mpesaPhone,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      defaultPayrollFrequency: defaultPayrollFrequency ?? this.defaultPayrollFrequency,
      defaultEmploymentType: defaultEmploymentType ?? this.defaultEmploymentType,
      defaultPropertyId: defaultPropertyId ?? this.defaultPropertyId,
      photoUrl: photoUrl ?? this.photoUrl,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      bankName: json['bankName'],
      bankCode: json['bankCode'],
      bankAccount: json['bankAccount'],
      mpesaPaybill: json['mpesaPaybill'],
      mpesaTill: json['mpesaTill'],
      mpesaPhone: json['mpesaPhone'],
      defaultPaymentMethod: json['defaultPaymentMethod'] ?? 'MPESA',
      defaultPayrollFrequency: json['defaultPayrollFrequency'] ?? 'MONTHLY',
      defaultEmploymentType: json['defaultEmploymentType'] ?? 'FIXED',
      defaultPropertyId: json['defaultPropertyId'],
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'bankCode': bankCode,
      'bankAccount': bankAccount,
      'mpesaPaybill': mpesaPaybill,
      'mpesaTill': mpesaTill,
      'mpesaPhone': mpesaPhone,
      'defaultPaymentMethod': defaultPaymentMethod,
      'defaultPayrollFrequency': defaultPayrollFrequency,
      'defaultEmploymentType': defaultEmploymentType,
      'defaultPropertyId': defaultPropertyId,
      'photoUrl': photoUrl,
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

    // Try to load settings from API if authenticated
    try {
      final token = await ApiService().getToken();
      debugPrint('[SettingsProvider] Token present: ${token != null}');
      if (token != null) {
        final response = await ApiService().get('/users/profile');
        debugPrint('[SettingsProvider] Profile API status: ${response.statusCode}');
        if (response.statusCode == 200) {
          debugPrint('[SettingsProvider] Profile data: ${response.data}');
          final settings = UserSettings.fromJson(response.data).copyWith(
            themeMode: themeMode,
          );
          debugPrint('[SettingsProvider] Parsed bankName: ${settings.bankName}');
          debugPrint('[SettingsProvider] Parsed mpesaPhone: ${settings.mpesaPhone}');
          return settings;
        }
      }
    } catch (apiError) {
      // API failed, use defaults
      debugPrint('[SettingsProvider] API Error: $apiError');
      if (apiError is! DioException || apiError.response?.statusCode != 401) {
        debugPrint('Failed to load settings: $apiError');
      }
    }

    // Fallback to defaults
    debugPrint('[SettingsProvider] Using defaults');
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

  Future<void> updateBankAccount(String bankName, String? bankCode, String accountNumber) async {
    final current = state.value ?? UserSettings();
    state = AsyncValue.data(current.copyWith(
      bankName: bankName,
      bankCode: bankCode,
      bankAccount: accountNumber,
    ));

    // Persist to API
    await _saveToApi({
      'bankName': bankName,
      'bankCode': bankCode,
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

  Future<void> uploadProfilePhoto(List<int> bytes, String filename) async {
    final current = state.value ?? UserSettings();
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
        // 1. Upload
        final url = await ApiService().uploads.uploadAvatar(bytes, filename);
        // 2. Update Profile
        await _saveToApi({'photoUrl': url});
        
        // 3. Update local state
        return current.copyWith(photoUrl: url);
    });
  }

  Future<void> _saveToApi(Map<String, dynamic> updates) async {
    try {
      await ApiService().patch('/users/profile', data: updates);
      // Invalidate profileProvider so Edit Profile page stays in sync
      ref.invalidate(profileProvider);
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
