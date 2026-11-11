import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/repository/thread/thread_prefs_repository.provider.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/pages/chat/thread/thread_menu_controller.dart';

import '../../../domain/thread/fake_thread_prefs_repository.dart';

/// THR-M-07 and THR-M-08: the state behind the « ⋮ » menu of a thread and
/// its actions. A choice that succeeds shows at once, before the sync
/// echoes it; a change that fails leaves what is shown as it was and says
/// « The thread could not be changed. ».
void main() {
  setUp(() async {
    _repository = FakeThreadPrefsRepository();
    addTearDown(_repository.close);
    _container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [threadPrefsRepositoryProvider.overrideWithValue(_repository)],
    );
    _container.listen(_provider, (_, _) {});
    await pumpEventQueue();
  });

  test('before the account answers, nothing is shown yet', () {
    expect(_state().status, isNull);
  });

  group('shows what the account says', _shownTests);
  group('following and muting', _followTests);
  group('resolving', _resolveTests);
  group('a change that fails', _failureTests);
}

late FakeThreadPrefsRepository _repository;
late ProviderContainer _container;

final _provider = threadMenuControllerProvider(lunchThread);

ThreadMenuState _state() => _container.read(_provider);

ThreadMenuController _menu() => _container.read(_provider.notifier);

Future<void> _accountSays(
  ThreadFollow follow, {
  bool isResolved = false,
}) async {
  _repository.show(statusOf(follow, isResolved: isResolved));
  await pumpEventQueue();
}

void _expectFollow(ThreadFollow follow) =>
    expect(_state().status?.follow, follow);

void _expectAsked(ThreadChange change) => expect(_repository.changes, [change]);

void _shownTests() {
  test('the status of the thread', () async {
    await _accountSays(muted, isResolved: true);

    expect(_state().status, statusOf(muted, isResolved: true));
  });

  test('a change made on the web replaces it', () async {
    await _accountSays(followed);

    await _accountSays(muted);

    _expectFollow(muted);
  });
}

void _followTests() {
  test('follow saves « follow » and shows the thread followed', () async {
    await _accountSays(notFollowed);

    await _menu().follow();

    _expectAsked(const PrefSaved(lunchThread, ThreadPref.follow));
    _expectFollow(followed);
  });

  test('unfollow saves « unfollow » and shows it not followed', () async {
    await _accountSays(followed);

    await _menu().unfollow();

    _expectAsked(const PrefSaved(lunchThread, ThreadPref.unfollow));
    _expectFollow(notFollowed);
  });

  test('mute saves « mute » and shows it muted, still followed', () async {
    await _accountSays(followed);

    await _menu().mute();

    _expectAsked(const PrefSaved(lunchThread, ThreadPref.mute));
    _expectFollow(muted);
  });

  test('unmute saves « follow » and shows it followed again', () async {
    await _accountSays(muted);

    await _menu().unmute();

    _expectAsked(const PrefSaved(lunchThread, ThreadPref.follow));
    _expectFollow(followed);
  });

  test('unfollowing a muted thread unmutes it too', () async {
    await _accountSays(muted);

    await _menu().unfollow();

    _expectFollow(notFollowed);
  });
}

void _resolveTests() {
  test('resolve sends resolved true and shows it resolved', () async {
    await _accountSays(followed);

    await _menu().resolve();

    _expectAsked(const ResolvedSaved(lunchThread, resolved: true));
    expect(_state().status?.isResolved, isTrue);
  });

  test('reopen sends resolved false and shows it open', () async {
    await _accountSays(followed, isResolved: true);

    await _menu().reopen();

    _expectAsked(const ResolvedSaved(lunchThread, resolved: false));
    expect(_state().status?.isResolved, isFalse);
  });
}

void _failureTests() {
  setUp(() => _repository.isDown = true);

  test('a choice refused: the thread shows as before, and the failure is '
      'told', () async {
    await _accountSays(followed);

    final isSaved = await _menu().mute();

    expect(isSaved, isFalse);
    expect(_state().status, statusOf(followed));
  });

  test('a resolve refused: still open, and the failure is told', () async {
    await _accountSays(followed);

    final isSaved = await _menu().resolve();

    expect(isSaved, isFalse);
    expect(_state().status?.isResolved, isFalse);
  });

  test('the next change that succeeds no longer tells a failure', () async {
    await _accountSays(followed);
    await _menu().mute();

    _repository.isDown = false;
    final isSaved = await _menu().mute();

    expect(isSaved, isTrue);
    _expectFollow(muted);
  });
}
