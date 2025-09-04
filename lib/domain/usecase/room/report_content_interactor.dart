import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/report_content_state.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:matrix/matrix.dart';

class ReportContentInteractor {
  Stream<Either<Failure, Success>> execute({
    required Client client,
    required String roomId,
    required String eventId,
    required int score,
    required String reason,
  }) async* {
    try {
      yield const Right(ReportContentLoading());
      final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
        future: () => client.reportContent(
          roomId,
          eventId,
          score: score,
          reason: reason,
        ),
      );
      if (result.error != null) throw result.error!;
      yield const Right(ReportContentSuccess());
    } catch (e) {
      yield Left(ReportContentFailure(exception: e));
    }
  }
}
