import 'package:twake_chat/data/datasource/report/report_datasource.dart';
import 'package:twake_chat/domain/repository/report/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl(this._datasource);

  final ReportDatasource _datasource;

  @override
  Future<void> reportRoom({required String roomId, required String reason}) =>
      _datasource.reportRoom(roomId: roomId, reason: reason);
}
