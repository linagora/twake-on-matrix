import 'package:twake_chat/domain/model/chat/message_report_reason.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/report/report_flow_dialogs.dart';
import 'package:twake_chat/presentation/model/report/report_draft.dart';

class ReportFlow {
  const ReportFlow({required ReportFlowDialogs dialogs, required L10n l10n})
    : _dialogs = dialogs,
      _l10n = l10n;

  final ReportFlowDialogs _dialogs;
  final L10n _l10n;

  Future<void> run({
    required String title,
    required String description,
    required Future<void> Function(String reason) submit,
  }) async {
    final draft = await _pickDraft(title: title, description: description);
    if (draft == null) return;
    await _confirmAndSubmit(draft, submit);
  }

  String reasonText(ReportDraft draft) {
    final reason = draft.reason.getReason(_l10n);
    return draft.reason == MessageReportReason.other
        ? '$reason: ${draft.comment}'
        : reason;
  }

  Future<ReportDraft?> _pickDraft({
    required String title,
    required String description,
  }) async {
    while (true) {
      final reason = await _dialogs.pickReason(
        title: title,
        description: description,
      );
      if (reason == null) return null;
      if (reason != MessageReportReason.other) {
        return ReportDraft(reason: reason);
      }
      switch (await _dialogs.askComment()) {
        case ReportCommentBack():
          continue;
        case ReportCommentDismissed():
          return null;
        case ReportCommentSubmitted(:final comment):
          return ReportDraft(reason: reason, comment: comment);
      }
    }
  }

  Future<void> _confirmAndSubmit(
    ReportDraft draft,
    Future<void> Function(String reason) submit,
  ) async {
    final reason = reasonText(draft);
    while (await _dialogs.confirm(reason)) {
      final error = await _dialogs.runWithLoading(() => submit(reason));
      if (error == null) {
        _dialogs.showReported();
        return;
      }
      _dialogs.showFailed(error);
    }
  }
}
