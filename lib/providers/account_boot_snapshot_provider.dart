import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/account/entities/account_boot_snapshot.dart';

part 'account_boot_snapshot_provider.g.dart';

/// What `main` read from the store before the first frame, set once before
/// anything reads the account state. Without it nobody is persisted as active
/// and no removal is pending.
@Riverpod(keepAlive: true)
class BootAccountSnapshot extends _$BootAccountSnapshot {
  @override
  AccountBootSnapshot build() => const AccountBootSnapshot();

  void set(AccountBootSnapshot snapshot) => state = snapshot;
}
