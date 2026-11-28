import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/report/usecases/report_room_usecase.provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/report/material_report_flow_dialogs.dart';
import 'package:twake_chat/pages/report/report_flow.dart';

mixin ReportRoomMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  Future<void> reportRoom(BuildContext context, String roomId) {
    final l10n = L10n.of(context)!;
    final useCase = ref.read(reportRoomUseCaseProvider);
    return ReportFlow(
      dialogs: MaterialReportFlowDialogs(context),
      l10n: l10n,
    ).run(
      title: l10n.report,
      description: l10n.reportChatDesc,
      submit: (reason) => useCase.execute(roomId: roomId, reason: reason),
    );
  }
}
