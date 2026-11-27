import 'package:flutter/material.dart';
import 'package:twake_chat/pages/chat/chat_input_row_style.dart';
import 'package:twake_chat/domain/personalization/personalize_step.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/personalize/personalize_question.dart';
import 'package:twake_chat/pages/personalize/personalize_drawings.dart';
import 'package:twake_chat/widgets/app_bars/twake_app_bar.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';

/// Settings › Personalization: the choices of the start flow, in its order,
/// on one page.
class SettingsPersonalization extends StatelessWidget {
  const SettingsPersonalization({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    // A phone keeps its own message field: no choice of it there.
    final isWide = !ChatInputRowStyle.responsiveUtils.isMobile(context);
    return Scaffold(
      appBar: TwakeAppBar(
        title: l10n.personalization,
        context: context,
        withDivider: true,
        enableLeftTitle: true,
        leading: TwakeIconButton(
          paddingAll: 8,
          icon: Icons.arrow_back_ios,
          tooltip: l10n.back,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final step in PersonalizeStep.values)
            if (isWide || !step.isWideOnly)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    Text(
                      personalizeQuestion(l10n, step),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    PersonalizeStepCards(step: step),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
