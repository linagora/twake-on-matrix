import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

enum MessageReportReason {
  spam(score: -95),
  violence(score: -96),
  childAbuse(score: -97),
  pornography(score: -98),
  copyrightInfringement(score: -99),
  terrorism(score: -100),
  other(score: -90);

  const MessageReportReason({required this.score});

  final int score;
}

extension MessageReportReasonExtension on MessageReportReason {
  String getReason(L10n l10n) {
    switch (this) {
      case MessageReportReason.spam:
        return l10n.spam;
      case MessageReportReason.violence:
        return l10n.violence;
      case MessageReportReason.childAbuse:
        return l10n.childAbuse;
      case MessageReportReason.pornography:
        return l10n.pornography;
      case MessageReportReason.copyrightInfringement:
        return l10n.copyrightInfringement;
      case MessageReportReason.terrorism:
        return l10n.terrorism;
      case MessageReportReason.other:
        return l10n.other;
    }
  }

  Widget? getTrailingIcon() {
    switch (this) {
      case MessageReportReason.other:
        return Icon(
          Icons.arrow_forward_ios_outlined,
          size: 12,
          color: LinagoraRefColors.material().tertiary[30],
        );
      default:
        return null;
    }
  }
}
