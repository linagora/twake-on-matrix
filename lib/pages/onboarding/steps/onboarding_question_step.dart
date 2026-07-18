import 'package:fluffychat/pages/onboarding/onboarding_view_style.dart';
import 'package:fluffychat/pages/onboarding/widgets/onboarding_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

/// A single "eye-opening" question: a concern framed as a question, three
/// answers (don't care / don't know / concerned), and a single value reveal
/// shown once any answer is picked.
class OnboardingQuestionStep extends StatefulWidget {
  final String question;
  final String valueReveal;
  final VoidCallback onContinue;

  const OnboardingQuestionStep({
    super.key,
    required this.question,
    required this.valueReveal,
    required this.onContinue,
  });

  @override
  State<OnboardingQuestionStep> createState() => _OnboardingQuestionStepState();
}

class _OnboardingQuestionStepState extends State<OnboardingQuestionStep> {
  int? _selectedIndex;

  List<String> _answers(L10n l10n) => [
    l10n.onboardingAnswerDontCare,
    l10n.onboardingAnswerDontKnow,
    l10n.onboardingAnswerConcerned,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final colors = LinagoraSysColors.material();
    final theme = Theme.of(context);
    final answers = _answers(l10n);
    final hasAnswered = _selectedIndex != null;

    return Padding(
      padding: OnboardingViewStyle.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8.0),
          Text(
            widget.question,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: OnboardingViewStyle.titleSpacing),
          for (var i = 0; i < answers.length; i++)
            Padding(
              padding: const EdgeInsets.only(
                bottom: OnboardingViewStyle.optionSpacing,
              ),
              child: _AnswerOption(
                label: answers[i],
                isSelected: _selectedIndex == i,
                onTap: () => setState(() => _selectedIndex = i),
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: hasAnswered
                  ? Align(
                      key: const ValueKey('reveal'),
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.only(top: 8.0),
                        padding: OnboardingViewStyle.optionPadding,
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer,
                          borderRadius: BorderRadius.circular(
                            OnboardingViewStyle.optionRadius,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Text(
                                widget.valueReveal,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          OnboardingPrimaryButton(
            label: l10n.onboardingContinue,
            onTap: hasAnswered ? widget.onContinue : null,
          ),
        ],
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LinagoraSysColors.material();
    final theme = Theme.of(context);
    return Material(
      color: isSelected ? colors.secondaryContainer : colors.surface,
      borderRadius: BorderRadius.circular(OnboardingViewStyle.optionRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(OnboardingViewStyle.optionRadius),
        onTap: onTap,
        child: Container(
          padding: OnboardingViewStyle.optionPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              OnboardingViewStyle.optionRadius,
            ),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outline,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
