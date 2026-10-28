import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';

/// A lost connection, as opposed to a bug or a server error. The sync loop
/// wraps these in [SyncConnectionException]; anything else it wraps stays a
/// failure.
bool isOfflineFailure(Object error) => switch (error) {
  SocketException() || TimeoutException() || http.ClientException() => true,
  SyncConnectionException(:final originalException) => isOfflineFailure(
    originalException,
  ),
  _ => false,
};

/// Logs [error] at warning when it is a lost connection, and reports whether
/// it did. The caller keeps every other error at error level.
bool warnIfOffline(Object error, StackTrace? stackTrace, String what) {
  if (!isOfflineFailure(error)) return false;
  Logs().w(what, error, stackTrace);
  return true;
}
