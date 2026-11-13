/// Reads the current homeserver's advisory maximum upload size in bytes.
abstract interface class DriveUploadLimitSource {
  /// Returns null when the server gives no size or its config cannot be read.
  Future<int?> read();
}
