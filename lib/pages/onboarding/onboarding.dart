import 'package:fluffychat/pages/onboarding/onboarding_view.dart';
import 'package:fluffychat/utils/onboarding_settings.dart';
import 'package:fluffychat/utils/permission_service.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum OnboardingStep {
  hook,
  privacy,
  ai,
  sovereignty,
  notifications,
  contacts;

  bool get isLast => this == OnboardingStep.values.last;
}

/// Pre-auth value onboarding. A short hook, three "eye-opening" questions that
/// each surface a concern Twake answers (privacy, AI, sovereignty), then the
/// notifications and contacts permission asks. The contacts match reveal
/// (payoff) runs after the first login — see [OnboardingPayoffPage].
class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => OnboardingController();
}

class OnboardingController extends State<Onboarding> {
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeInOut;

  final PageController pageController = PageController();

  final PermissionHandlerService _permissionService =
      PermissionHandlerService();

  final ValueNotifier<OnboardingStep> currentStepNotifier = ValueNotifier(
    OnboardingStep.hook,
  );

  final ValueNotifier<bool> isRequestingContactsNotifier = ValueNotifier(false);

  final ValueNotifier<bool> isRequestingNotificationsNotifier = ValueNotifier(
    false,
  );

  void onPageChanged(int index) {
    currentStepNotifier.value = OnboardingStep.values[index];
  }

  void goToNextStep() {
    final current = currentStepNotifier.value;
    if (current.isLast) {
      _finishOnboarding();
      return;
    }
    _animateTo(OnboardingStep.values[current.index + 1]);
  }

  void _animateTo(OnboardingStep step) {
    pageController.animateToPage(
      step.index,
      duration: animationDuration,
      curve: animationCurve,
    );
  }

  Future<void> onRequestNotificationsPermission() async {
    if (isRequestingNotificationsNotifier.value) return;
    isRequestingNotificationsNotifier.value = true;
    try {
      await Permission.notification.request();
      if (!mounted) return;
      goToNextStep();
    } finally {
      if (mounted) isRequestingNotificationsNotifier.value = false;
    }
  }

  Future<void> onRequestContactsPermission() async {
    if (isRequestingContactsNotifier.value) return;
    isRequestingContactsNotifier.value = true;
    try {
      // Request the OS permission now; the actual address-book sync runs
      // after login (when an access token is available).
      await _permissionService.requestContactsPermissionActions();
      if (!mounted) return;
      goToNextStep();
    } finally {
      if (mounted) isRequestingContactsNotifier.value = false;
    }
  }

  void onSkipStep() => goToNextStep();

  Future<void> _finishOnboarding() async {
    await OnboardingSettings.setCompleted();
    if (!mounted) return;
    // Hand back to the root route, which sends the user to the auth screen
    // (or straight to the chat list if already logged in).
    TwakeApp.router.go('/');
  }

  @override
  void dispose() {
    pageController.dispose();
    currentStepNotifier.dispose();
    isRequestingContactsNotifier.dispose();
    isRequestingNotificationsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OnboardingView(controller: this);
}
