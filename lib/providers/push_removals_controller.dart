import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/account/push_removal_plan.dart';
import 'package:twake_chat/data/account/push_teardown.dart';
import 'package:twake_chat/data/account/repositories/account_repository_impl.provider.dart';
import 'package:twake_chat/providers/account_services_providers.dart';

part 'push_removals_controller.g.dart';

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
          teardown.report,
        );
  }
}
