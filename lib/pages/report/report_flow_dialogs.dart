import 'package:twake_chat/domain/model/chat/message_report_reason.dart';

sealed class ReportCommentAnswer {
  const ReportCommentAnswer();
}

class ReportCommentBack extends ReportCommentAnswer {
  const ReportCommentBack();
}

class ReportCommentDismissed extends ReportCommentAnswer {
  const ReportCommentDismissed();
}

class ReportCommentSubmitted extends ReportCommentAnswer {
  const ReportCommentSubmitted(this.comment);

  final String comment;
}

abstract interface class ReportFlowDialogs {
  Future<MessageReportReason?> pickReason({
    required String title,
    required String description,
  });

  Future<ReportCommentAnswer> askComment();

  Future<bool> confirm(String reason);

  Future<Object?> runWithLoading(Future<void> Function() action);

  void showReported();

  void showFailed(Object error);
}
