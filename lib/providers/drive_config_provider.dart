import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/drive/entities/drive_config.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

part 'drive_config_provider.g.dart';

// The summary may be another server's while an account is being added.
@Riverpod(keepAlive: true)
DriveConfig driveConfig(Ref ref) {
  final summary = ref.watch(loginHomeserverSummaryProvider);
  final active = ref.watch(activeMatrixClientProvider);
  final ofActive =
      active == null || summary?.describes(active.homeserver) == true;
  return (ofActive ? summary : null).twakeDriveConfig;
}
