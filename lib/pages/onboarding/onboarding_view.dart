import 'package:fluffychat/pages/onboarding/onboarding.dart';
import 'package:fluffychat/pages/onboarding/onboarding_view_style.dart';
import 'package:fluffychat/pages/onboarding/steps/onboarding_contacts_step.dart';
import 'package:fluffychat/pages/onboarding/steps/onboarding_hook_step.dart';
import 'package:fluffychat/pages/onboarding/steps/onboarding_notifications_step.dart';
import 'package:fluffychat/pages/onboarding/steps/onboarding_question_step.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class OnboardingView extends StatelessWidget {
  final OnboardingController controller;

  const OnboardingView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final colors = LinagoraSysColors.material();
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: controller.pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: controller.onPageChanged,
                children: [
                  OnboardingHookStep(onContinue: controller.goToNextStep),
                  OnboardingQuestionStep(
                    question: l10n.onboardingPrivacyQuestion,
                    valueReveal: l10n.onboardingPrivacyValue,
                    onContinue: controller.goToNextStep,
                  ),
                  OnboardingQuestionStep(
                    question: l10n.onboardingAiQuestion,
                    valueReveal: l10n.onboardingAiValue,
                    onContinue: controller.goToNextStep,
                  ),
                  OnboardingQuestionStep(
                    question: l10n.onboardingSovereigntyQuestion,
                    valueReveal: l10n.onboardingSovereigntyValue,
                    onContinue: controller.goToNextStep,
                  ),
                  OnboardingNotificationsStep(
                    isRequestingNotifier:
                        controller.isRequestingNotificationsNotifier,
                    onAllow: controller.onRequestNotificationsPermission,
                    onSkip: controller.onSkipStep,
                  ),
                  OnboardingContactsStep(
                    isRequestingNotifier:
                        controller.isRequestingContactsNotifier,
                    onAllow: controller.onRequestContactsPermission,
                    onSkip: controller.onSkipStep,
                  ),
                ],
              ),
            ),
            _PageIndicator(currentStepNotifier: controller.currentStepNotifier),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final ValueNotifier<OnboardingStep> currentStepNotifier;

  const _PageIndicator({required this.currentStepNotifier});

  @override
  Widget build(BuildContext context) {
    final colors = LinagoraSysColors.material();
    return ValueListenableBuilder<OnboardingStep>(
      valueListenable: currentStepNotifier,
      builder: (context, current, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: OnboardingStep.values.map((step) {
            final isActive = step == current;
            return Container(
              width: OnboardingViewStyle.pageIndicatorSize,
              height: OnboardingViewStyle.pageIndicatorSize,
              margin: const EdgeInsets.symmetric(
                horizontal: OnboardingViewStyle.pageIndicatorSpacing / 2,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? colors.primary : colors.outlineVariant,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
