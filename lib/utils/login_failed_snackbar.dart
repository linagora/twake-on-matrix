import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/localized_exception_extension.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_chat/widgets/twake_app.dart';

/// Tells the user why a login that worked on the server was undone. No-op
/// when the app has no navigator (the screen that started it is gone).
void showLoginFailedSnackBar(Object? error) {
  final context = TwakeApp.routerKey.currentContext;
  if (context == null || !context.mounted) return;
  TwakeSnackBar.show(
    context,
    error?.toLocalizedString(context) ??
        L10n.of(context)!.oopsSomethingWentWrong,
  );
}
