import 'package:twake_chat/domain/repository/report/report_repository.dart';

class ReportUserUseCase {
  const ReportUserUseCase(this._repository);

  final ReportRepository _repository;

  Future<void> execute({required String userId, required String reason}) =>
      _repository.reportUser(userId: userId, reason: reason);
}
