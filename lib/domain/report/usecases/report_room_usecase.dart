import 'package:twake_chat/domain/repository/report/report_repository.dart';

class ReportRoomUseCase {
  const ReportRoomUseCase(this._repository);

  final ReportRepository _repository;

  Future<void> execute({required String roomId, required String reason}) =>
      _repository.reportRoom(roomId: roomId, reason: reason);
}
