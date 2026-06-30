import 'package:shared_preferences/shared_preferences.dart';

/// Device-level flag tracking whether the value-onboarding flow has been
/// completed (or explicitly skipped). Stored per device because the flow is
/// about local permissions (contacts, notifications), not account state.
class OnboardingSettings {
  static const String _onboardingCompletedKey = 'onboarding_completed';

  const OnboardingSettings._();

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  static Future<void> setCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }
}
