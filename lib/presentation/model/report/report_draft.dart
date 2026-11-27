import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/model/chat/message_report_reason.dart';

part 'report_draft.freezed.dart';

@freezed
abstract class ReportDraft with _$ReportDraft {
  const factory ReportDraft({
    required MessageReportReason reason,
    @Default('') String comment,
  }) = _ReportDraft;
}
