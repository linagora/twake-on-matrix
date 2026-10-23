import 'package:twake_chat/domain/account/entities/account.dart';

/// Hands the accounts that exist when the app starts to the account
/// repository, which has no other way to learn them (the clients are created
/// before the first frame).
abstract interface class AccountBootPort {
  /// Registers the accounts of the boot, dropping from [pendingRemovals] the
  /// ones that are gone, and returns them in store order.
  List<Account> adopt({Set<String> pendingRemovals = const {}});
}
