import 'package:flutter/widgets.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/clipboard.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';

extension CopyMessageLinkExtension on BuildContext {
  /// Copies [link] to the clipboard, then says it was copied; when the
  /// clipboard refuses, shows [link] to copy by hand, as the web app does.
  Future<void> copyMessageLink(String link) async {
    final l10n = L10n.of(this)!;
    final copied = await TwakeClipboard.instance.tryCopyText(link);
    if (!mounted) return;
    TwakeSnackBar.show(this, copied ? l10n.linkCopied : l10n.linkToCopy(link));
  }
}
