import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/date_time_extension.dart';

/// Between a status and the presence: `status · presence`.
const presenceSubtitleSeparator = ' · ';

extension PersonPresenceExtension on PersonPresence {
  LinagoraPresence get badge => switch (status) {
    PresenceStatus.online => LinagoraPresence.online,
    PresenceStatus.away => LinagoraPresence.away,
    PresenceStatus.offline => LinagoraPresence.offline,
  };

  String localizedPresence(L10n l10n) {
    if (status == PresenceStatus.online) return l10n.online;
    final lastActiveAt = this.lastActiveAt;
    if (lastActiveAt == null) return l10n.offline;
    final elapsed = DateTime.now().difference(lastActiveAt);
    if (lastActiveAt.isLessThanOneHourAgo()) {
      return l10n.onlineMinAgo(elapsed.inMinutes.clamp(1, 59));
    }
    if (lastActiveAt.isLessThanADayAgo()) {
      return l10n.onlineHourAgo((elapsed.inMinutes / 60).round());
    }
    if (lastActiveAt.isLessThan30DaysAgo()) {
      return l10n.onlineDayAgo(elapsed.inDays);
    }
    return l10n.aWhileAgo;
  }

  /// `status · presence`, the presence alone without a status.
  String localizedSubtitle(L10n l10n) {
    final presence = localizedPresence(l10n);
    final statusMessage = this.statusMessage;
    return statusMessage == null
        ? presence
        : '$statusMessage$presenceSubtitleSeparator$presence';
  }
}
