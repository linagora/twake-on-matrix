abstract interface class ReportRepository {
  Future<void> reportRoom({required String roomId, required String reason});

  Future<void> reportUser({required String userId, required String reason});
}
