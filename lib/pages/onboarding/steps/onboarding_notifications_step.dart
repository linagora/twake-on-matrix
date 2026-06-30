import 'package:fluffychat/pages/onboarding/onboarding_view_style.dart';
import 'package:fluffychat/pages/onboarding/widgets/onboarding_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class OnboardingNotificationsStep extends StatelessWidget {
  final ValueNotifier<bool> isRequestingNotifier;
  final VoidCallback onAllow;
  final VoidCallback onSkip;

  const OnboardingNotificationsStep({
    super.key,
    required this.isRequestingNotifier,
    required this.onAllow,
    required this.onSkip,
  });

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
                    Icons.notifications_outlined,
                    size: OnboardingViewStyle.iconSize,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: OnboardingViewStyle.titleSpacing),
                Text(
                  l10n.onboardingNotificationsTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: OnboardingViewStyle.subtitleSpacing),
                Text(
                  l10n.onboardingNotificationsSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isRequestingNotifier,
            builder: (context, isRequesting, _) {
              return OnboardingPrimaryButton(
                label: l10n.onboardingNotificationsAllow,
                isLoading: isRequesting,
                onTap: onAllow,
              );
            },
          ),
          const SizedBox(height: 8.0),
          OnboardingTextButton(label: l10n.onboardingLater, onTap: onSkip),
        ],
      ),
    );
  }
}
