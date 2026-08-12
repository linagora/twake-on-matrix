import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/room/report_content_state.dart';
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
      await client.reportEvent(roomId, eventId, score: score, reason: reason);
      yield const Right(ReportContentSuccess());
    } catch (e) {
      yield Left(ReportContentFailure(exception: e));
    }
  }
}
