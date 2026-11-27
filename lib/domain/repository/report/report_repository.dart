abstract interface class ReportRepository {
  Future<void> reportRoom({required String roomId, required String reason});
}
