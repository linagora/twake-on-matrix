import 'package:twake_chat/domain/personalization/personalize_step.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

/// What [step] asks.
String personalizeQuestion(L10n l10n, PersonalizeStep step) => switch (step) {
  PersonalizeStep.density => l10n.personalizeDensityQuestion,
  PersonalizeStep.order => l10n.personalizeOrderQuestion,
  PersonalizeStep.seenStyle => l10n.personalizeSeenStyleQuestion,
  PersonalizeStep.align => l10n.personalizeAlignQuestion,
};
