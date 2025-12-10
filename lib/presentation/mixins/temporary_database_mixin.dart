import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/open_sqflite_db.dart';
import 'package:matrix/matrix.dart';

/// Mixin for managing temporary Matrix SDK databases during login flows.
///
/// This mixin provides:
/// - Creation of temporary databases with unique client names
/// - Automatic cleanup on errors or disposal
/// - Prevention of database leaks when login flow is cancelled
mixin TemporaryDatabaseMixin {
  MatrixSdkDatabase? _temporaryDatabase;

  /// Creates a temporary database with a unique client name.
  ///
  /// The database name is based on the current timestamp in microseconds
  /// to avoid collisions when multiple login attempts happen quickly.
  ///
  /// Returns the initialized database.
  Future<MatrixSdkDatabase> createTemporaryDatabase() async {
    final clientName =
        '${AppConfig.applicationName}-${DateTime.now().microsecondsSinceEpoch}';
    _temporaryDatabase = await MatrixSdkDatabase.init(
      clientName,
      database: await openSqfliteDb(name: clientName),
    );
    return _temporaryDatabase!;
  }

  /// Cleans up the temporary database if it exists.
  ///
  /// This method should be called:
  /// - In catch blocks when login fails
  /// - When login is cancelled or validation fails
  /// - In the dispose method of the controller
  ///
  /// Safe to call multiple times - handles null database gracefully.
  Future<void> cleanupTemporaryDatabase() async {
    if (_temporaryDatabase != null) {
      try {
        await _temporaryDatabase!.delete();
        Logs().d(
          'TemporaryDatabaseMixin::cleanupTemporaryDatabase - Cleaned up temporary database',
        );
      } catch (e) {
        Logs().e(
          'TemporaryDatabaseMixin::cleanupTemporaryDatabase - Error cleaning up database: $e',
        );
      } finally {
        _temporaryDatabase = null;
      }
    }
  }

  /// Dispose method to be called from controller's dispose.
  ///
  /// Usage in controller:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   disposeTemporaryDatabaseMixin();
  ///   super.dispose();
  /// }
  /// ```
  void disposeTemporaryDatabaseMixin() {
    cleanupTemporaryDatabase();
  }
}
