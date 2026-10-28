import 'package:matrix/matrix.dart' show Logs;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/account/logout_removals.dart';

part 'report_failure_provider.g.dart';

/// The one way to make a failure visible that the user does not see (a
/// logout step, a retried removal, a background setup): logged with its stack
/// trace at the level the error reporting forwards, so it reaches Sentry.
/// Override it in a test to collect the failures.
@Riverpod(keepAlive: true)
ReportFailure reportFailure(Ref ref) =>
    (error, stackTrace, what) => Logs().wtf(what, error, stackTrace);
