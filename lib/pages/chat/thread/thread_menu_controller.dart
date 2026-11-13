import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/exception/thread/thread_change_exception.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_status.dart';
import 'package:twake_chat/domain/thread/usecases/save_thread_pref_use_case.provider.dart';
import 'package:twake_chat/domain/thread/usecases/save_thread_resolved_use_case.provider.dart';
import 'package:twake_chat/domain/thread/usecases/watch_thread_use_case.provider.dart';

part 'thread_menu_controller.freezed.dart';
part 'thread_menu_controller.g.dart';

/// What the account says of a thread, as it changes (a sync, the web).
@riverpod
Stream<ThreadStatus> threadStatus(Ref ref, ThreadRef thread) =>
    ref.watch(watchThreadUseCaseProvider).execute(thread);

@freezed
abstract class ThreadMenuState with _$ThreadMenuState {
  const factory ThreadMenuState({
    /// Null until the account answers.
    ThreadStatus? status,

    /// A change is being saved: no second one meanwhile.
    @Default(false) bool isSaving,

    /// What the account says of the thread could not be read.
    @Default(false) bool hasFailed,
  }) = _ThreadMenuState;
}

/// The « ⋮ » menu of a thread. A change that succeeds shows at once, before
/// the sync echoes it; one that fails leaves what is shown as it was.
@riverpod
class ThreadMenuController extends _$ThreadMenuController {
  @override
  ThreadMenuState build(ThreadRef thread) {
    ref.listen(threadStatusProvider(thread), (_, next) {
      state = switch (next) {
        AsyncData(:final value) => state.copyWith(status: value),
        AsyncError() => state.copyWith(hasFailed: true),
        _ => state,
      };
    });
    return const ThreadMenuState();
  }

  /// Each action tells whether the change was saved.
  Future<bool> follow() => _choose(ThreadPref.follow);

  Future<bool> unfollow() => _choose(ThreadPref.unfollow);

  Future<bool> mute() => _choose(ThreadPref.mute);

  /// Back to following, as on the web.
  Future<bool> unmute() => _choose(ThreadPref.follow);

  Future<bool> resolve() => _setResolved(resolved: true);

  Future<bool> reopen() => _setResolved(resolved: false);

  Future<bool> _choose(ThreadPref pref) {
    final save = ref.read(saveThreadPrefUseCaseProvider);
    return _change(
      () => save.execute(thread, pref),
      (status) => status.copyWith(
        follow: ThreadFollow.resolve(participated: false, pref: pref),
      ),
    );
  }

  Future<bool> _setResolved({required bool resolved}) {
    final save = ref.read(saveThreadResolvedUseCaseProvider);
    return _change(
      () => save.execute(thread, resolved: resolved),
      (status) => status.copyWith(isResolved: resolved),
    );
  }

  /// Never throws: a failure leaves what is shown as it was and returns
  /// false.
  Future<bool> _change(
    Future<void> Function() save,
    ThreadStatus Function(ThreadStatus status) shown,
  ) async {
    state = state.copyWith(isSaving: true);
    try {
      await save();
    } on ThreadChangeFailedException {
      if (ref.mounted) state = state.copyWith(isSaving: false);
      return false;
    }
    if (!ref.mounted) return true;
    final status = state.status;
    state = state.copyWith(
      status: status == null ? null : shown(status),
      isSaving: false,
    );
    return true;
  }
}
