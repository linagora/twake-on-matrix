import 'package:fluffychat/pages/onboarding/onboarding_view_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class OnboardingPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LinagoraSysColors.material();
    return SizedBox(
      width: double.infinity,
      height: OnboardingViewStyle.buttonHeight,
      child: Material(
        color: colors.primary,
        borderRadius: BorderRadius.circular(OnboardingViewStyle.buttonRadius),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colors.onPrimary,
                    ),
                  )
                : Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: colors.onPrimary),
                  ),
          ),
        ),
      ),
    );
  }
}

class OnboardingTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const OnboardingTextButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LinagoraSysColors.material();
    return SizedBox(
      width: double.infinity,
      height: OnboardingViewStyle.buttonHeight,
      child: TextButton(
        onPressed: onTap,
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}
