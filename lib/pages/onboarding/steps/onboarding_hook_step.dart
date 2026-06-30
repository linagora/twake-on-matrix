import 'package:fluffychat/pages/onboarding/onboarding_view_style.dart';
import 'package:fluffychat/pages/onboarding/widgets/onboarding_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class OnboardingHookStep extends StatelessWidget {
  final VoidCallback onContinue;

  const OnboardingHookStep({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final colors = LinagoraSysColors.material();
    final theme = Theme.of(context);
    return Padding(
      padding: OnboardingViewStyle.screenPadding,
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: OnboardingViewStyle.iconBadgeSize,
                  height: OnboardingViewStyle.iconBadgeSize,
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: OnboardingViewStyle.iconSize,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: OnboardingViewStyle.titleSpacing),
                Text(
                  l10n.onboardingHookTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: OnboardingViewStyle.subtitleSpacing),
                Text(
                  l10n.onboardingHookSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          OnboardingPrimaryButton(
            label: l10n.onboardingContinue,
            onTap: onContinue,
          ),
        ],
      ),
    );
  }
}
