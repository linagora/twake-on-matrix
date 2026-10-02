import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_chat/widgets/twake_app.dart';

/// Tells the user that part of the phonebook could not be matched. No-op when
/// the app has no navigator yet (background refresh before the first frame).
void showContactLookupFailedSnackBar() {
  final context = TwakeApp.router.routerDelegate.navigatorKey.currentContext;
  if (context == null) return;
  TwakeSnackBar.show(context, L10n.of(context)!.contactLookupFailed);
}
