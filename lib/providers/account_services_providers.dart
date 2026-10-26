import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/account/client_subscriptions.dart';
import 'package:twake_chat/data/account/logout_removals.dart';

part 'account_services_providers.g.dart';

/// Every subscription kept for a client, so a rollback or a logout cancels
/// them all and none is started after that.
@Riverpod(keepAlive: true)
ClientSubscriptions clientSubscriptions(Ref ref) {
  final subscriptions = ClientSubscriptions();
  ref.onDispose(() => unawaited(subscriptions.cancelAll()));
  return subscriptions;
}

/// Removals of logged-out accounts that failed and are retried.
@Riverpod(keepAlive: true)
LogoutRemovals logoutRemovals(Ref ref) {
  final removals = LogoutRemovals();
  ref.onDispose(removals.dispose);
  return removals;
}

/// Pusher deletions that failed and are retried.
@Riverpod(keepAlive: true)
LogoutRemovals pushRemovals(Ref ref) {
  final removals = LogoutRemovals();
  ref.onDispose(removals.dispose);
  return removals;
}
