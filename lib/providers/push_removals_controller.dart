import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/account_services_providers.dart';
import 'package:twake_chat/providers/push_removal_plan.dart';

part 'push_removals_controller.g.dart';

/// The push state of the app (keychain sync, pushers, web push) that a pusher
/// deletion needs. `MatrixState` sets it after its first build and clears it
/// when it is disposed.
abstract interface class PushTeardown {
  /// Deletes the push registration of [target]; throws when it fails.
  Future<void> removePush(Client target);

  /// False while a mobile device has no push token yet.
  bool get isPushReady;

  /// Makes a failure of [what] visible.
  void report(Object error, StackTrace stackTrace, String what);
}

/// Deletes the pusher of an account before its logout, and retries a failed
/// deletion in the background through `pushRemovalsProvider`.
@Riverpod(keepAlive: true)
class PushRemovalsController extends _$PushRemovalsController {
  @override
  PushTeardown? build() => null;

  void setTeardown(PushTeardown teardown) => state = teardown;

  /// Clears [teardown] only when it is still the one set.
  void clearTeardown(PushTeardown teardown) {
    if (identical(state, teardown)) state = null;
  }

  /// The push teardown of [target], to run before its logout (while the
  /// session can still delete the pusher). A failure is reported and kept: it
  /// is recorded across restarts and runs again while the session of [target]
  /// is still open. Never throws, so the logout goes on.
  Future<void> removeBeforeLogout(Client target) async {
    final teardown = state;
    if (teardown == null) {
      Logs().w('PushRemovalsController: no teardown for ${target.clientName}');
      return;
    }
    await ref
        .read(pushRemovalsProvider)
        .remove(
          target.clientName,
          PushRemovalPlan(
            id: target.clientName,
            repository: ref.read(accountRepositoryProvider),
            sessionToken: () => target.isLogged() ? target.accessToken : null,
            removePush: () => teardown.removePush(target),
            isPushReady: () => teardown.isPushReady,
          ).steps,
          (error, stackTrace, what) => error is PushNotReadyException
              ? Logs().w('PushRemovalsController: $what', error, stackTrace)
              : teardown.report(error, stackTrace, what),
        );
  }
}
