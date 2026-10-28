import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/account/entities/account_boot_snapshot.dart';

part 'account_boot_snapshot_provider.g.dart';

/// What `main` read from the store before the first frame. Overridden when the
/// app container is created; reading it without an override is a bug.
@Riverpod(keepAlive: true)
AccountBootSnapshot bootAccountSnapshot(Ref ref) => throw UnimplementedError(
  'bootAccountSnapshotProvider must be overridden when the container is made',
);
