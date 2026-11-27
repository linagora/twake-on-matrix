abstract interface class ReportDatasource {
  Future<void> reportRoom({required String roomId, required String reason});
}
