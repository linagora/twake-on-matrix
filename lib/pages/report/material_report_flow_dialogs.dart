import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/dialog/options_dialog.dart';
import 'package:twake_chat/domain/exception/report/report_exception.dart';
import 'package:twake_chat/domain/model/chat/message_report_reason.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/chat_report_message_additional_reason_dialog.dart';
import 'package:twake_chat/pages/report/report_flow_dialogs.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/localized_exception_extension.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';

class MaterialReportFlowDialogs implements ReportFlowDialogs {
  const MaterialReportFlowDialogs(this._context);

  static const _compactWidth = 600;

  final BuildContext _context;

  L10n get _l10n => L10n.of(_context)!;

  bool get _isCompact => MediaQuery.sizeOf(_context).width < _compactWidth;

  @override
  Future<MessageReportReason?> pickReason({
    required String title,
    required String description,
  }) async {
    if (!_context.mounted) return null;
    final options = MessageReportReason.values
        .map(
          (reason) => LinagoraDialogOption(
            name: reason.getReason(_l10n),
            value: reason,
            trailingIcon: reason.getTrailingIcon(),
          ),
        )
        .toList();
    final selected =
        await showDialog<LinagoraDialogOption<MessageReportReason>>(
          context: _context,
          builder: (context) => OptionsDialog(
            title: title,
            description: description,
            isBottomSheet: _isCompact,
            availableOptions: options,
            onSelected: (option) => Navigator.pop(context, option),
          ),
        );
    return selected?.value;
  }

  @override
  Future<ReportCommentAnswer> askComment() async {
    if (!_context.mounted) return const ReportCommentDismissed();
    final answer = await showDialog<ReportCommentAnswer>(
      context: _context,
      builder: (context) => ChatReportMessageAdditionalReasonDialog(
        l10n: _l10n,
        isMobile: _isCompact,
        onCommentReport: (comment) =>
            Navigator.pop(context, ReportCommentSubmitted(comment)),
        onBack: () => Navigator.pop(context, const ReportCommentBack()),
      ),
    );
    return answer ?? const ReportCommentDismissed();
  }

  @override
  Future<bool> confirm(String reason) async {
    if (!_context.mounted) return false;
    final result = await showConfirmAlertDialog(
      context: _context,
      title: _l10n.reportConfirmTitle,
      message: _l10n.reportConfirmMessage(reason),
      okLabel: _l10n.sendReport,
      cancelLabel: _l10n.cancel,
    );
    return result == ConfirmResult.ok;
  }

  @override
  Future<Object?> runWithLoading(Future<void> Function() action) async {
    final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: action,
    );
    return result.error;
  }

  @override
  void showReported() {
    if (!_context.mounted) return;
    TwakeSnackBar.show(_context, _l10n.contentHasBeenReported);
  }

  @override
  void showFailed(Object error) {
    if (!_context.mounted) return;
    final cause = error is ReportException ? error.cause ?? error : error;
    TwakeSnackBar.show(_context, cause.toLocalizedString(_context));
  }
}
