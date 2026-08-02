import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider not initialized');
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

class SettingsState {
  final bool isDarkMode;
  final bool notificationsEnabled;
  final String senderEmail;

  SettingsState({
    required this.isDarkMode,
    required this.notificationsEnabled,
    required this.senderEmail,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    bool? notificationsEnabled,
    String? senderEmail,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      senderEmail: senderEmail ?? this.senderEmail,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs)
      : super(SettingsState(
          isDarkMode: _prefs.getBool(AppConstants.keyDarkMode) ?? false,
          notificationsEnabled: _prefs.getBool(AppConstants.keyNotifications) ?? true,
          senderEmail: _prefs.getString('senderEmail') ?? AppConstants.defaultSenderEmail,
        ));

  void toggleDarkMode(bool value) {
    _prefs.setBool(AppConstants.keyDarkMode, value);
    state = state.copyWith(isDarkMode: value);
  }

  void toggleNotifications(bool value) {
    _prefs.setBool(AppConstants.keyNotifications, value);
    state = state.copyWith(notificationsEnabled: value);
  }

  void setSenderEmail(String email) {
    _prefs.setString('senderEmail', email);
    state = state.copyWith(senderEmail: email);
  }
}
