import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/scribe/scribe_failure_message.dart';

void main() {
  final l10n = lookupL10n(const Locale('en'));
  const message = ScribeFailureMessage();

  final cases = <(Exception, String?)>[
    (const ScribeNotOffered(), l10n.scribeNotOffered),
    (const ScribeEmptyDraft(), null),
    (const ScribeRewriteFailed(), l10n.scribeRewriteFailed),
    (const ScribeRoomNotFound(), l10n.scribeRewriteFailed),
    (const ScribeSwitchFailed(), l10n.scribeSettingFailed),
    (const DriveSignInCancelled(), null),
    (const DriveSessionSuperseded(), null),
    (
      const DriveSignInFailed(DriveSignInFailure.browser),
      l10n.scribeSignInFailed,
    ),
    (const DriveWorkplaceUnknown(), l10n.scribeSignInFailed),
    (const DriveExchangeRejected(), l10n.scribeSignInFailed),
    (const DriveChatAppMissing(), l10n.driveChatAppMissing),
    (const DriveRateLimited(), l10n.scribeRateLimited),
    (const DriveTimedOut(), l10n.scribeTimedOut),
    (const DriveOffline(), l10n.scribeOffline),
    (const DriveNotConfigured(), l10n.scribeRewriteFailed),
    (const DriveIntentFailed(), l10n.scribeRewriteFailed),
    (const FormatException('other'), l10n.scribeRewriteFailed),
  ];

  for (final (error, expected) in cases) {
    test('${error.runtimeType} shows ${expected ?? 'nothing'}', () {
      expect(message.of(l10n, error), expected);
    });
  }
}
