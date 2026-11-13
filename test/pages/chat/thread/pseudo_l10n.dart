import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/generated/l10n/app_localizations_en.dart';

/// [english] as the pseudo locale spells it.
String pseudo(String english) => '⟦$english⟧';

/// English with the thread strings marked by [pseudo]: a widget shows a
/// marked label only if it took it from the strings of the app locale, so a
/// label written in the code shows unmarked. The other locales than English
/// come from Weblate and may not have these strings yet: their text proves
/// nothing.
class _PseudoL10n extends L10nEn {
  @override
  String get threadFollow => pseudo(super.threadFollow);

  @override
  String get threadUnfollow => pseudo(super.threadUnfollow);

  @override
  String get threadMute => pseudo(super.threadMute);

  @override
  String get threadUnmute => pseudo(super.threadUnmute);

  @override
  String get threadMarkResolved => pseudo(super.threadMarkResolved);

  @override
  String get threadReopen => pseudo(super.threadReopen);

  @override
  String get threadResolved => pseudo(super.threadResolved);

  @override
  String get threadChangeFailed => pseudo(super.threadChangeFailed);

  @override
  String get oopsSomethingWentWrong => pseudo(super.oopsSomethingWentWrong);
}

/// Gives the app the pseudo locale, in place of `L10n.delegate`.
class PseudoL10nDelegate extends LocalizationsDelegate<L10n> {
  const PseudoL10nDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<L10n> load(Locale locale) => SynchronousFuture(_PseudoL10n());

  @override
  bool shouldReload(PseudoL10nDelegate old) => false;
}
