import 'package:twake_chat/domain/model/call/call_line.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

extension CallLineExtension on CallLine {
  String title(L10n l10n) => switch ((isOutgoing, isVideo)) {
    (true, false) => l10n.callLineOutgoing,
    (true, true) => l10n.callLineOutgoingVideo,
    (false, false) => l10n.callLineIncoming,
    (false, true) => l10n.callLineIncomingVideo,
  };

  /// The outcome, or the duration of an answered call.
  String status(L10n l10n) => switch (outcome) {
    CallLineOutcome.answered => _formatDuration(duration ?? Duration.zero),
    CallLineOutcome.missed => l10n.callLineMissed,
    CallLineOutcome.canceled => l10n.callLineCanceled,
  };

  String previewText(L10n l10n) => outcome == CallLineOutcome.missed
      ? (isVideo ? l10n.callLineMissedVideoCall : l10n.callLineMissedCall)
      : title(l10n);

  static String _formatDuration(Duration duration) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '${duration.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}
