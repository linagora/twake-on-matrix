import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/datasource_impl/thread/thread_prefs_datasource_impl.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import '../../data/datasource_impl/thread/thread_account.dart';

/// THR-M-07, review of P2: one rule tells whether the user follows a thread
/// and whether it is muted, for the badge, the notifications and the menu:
/// the explicit choice (the one just saved here included) wins over taking
/// part; a muted thread stays followed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _account = ThreadAccount(RecordingHomeserver());
    await _account.start();
  });

  test('a thread the user never wrote in is not followed', () {
    expect(_store.followOf(lunchThread), _notFollowed);
  });

  test('a thread the user wrote in is followed', () {
    _store.markFollowed(lunchThread);

    expect(_store.followOf(lunchThread), _followed);
  });

  test('a thread the user wrote in, then unfollowed on the web, is not '
      'followed', () async {
    _store.markFollowed(lunchThread);

    await _account.webWrites([prefEntry(lunchThread, WirePref.unfollow)]);

    expect(_store.followOf(lunchThread), _notFollowed);
  });

  test('a thread muted on the web is followed and muted', () async {
    await _account.webWrites([prefEntry(lunchThread, WirePref.mute)]);

    expect(_store.followOf(lunchThread), _muted);
  });

  test('a thread muted here, before the sync echoes it, is followed and '
      'muted', () async {
    await ThreadPrefsDatasourceImpl(
      _account,
    ).saveThreadPref(lunchThread, ThreadPref.mute);

    expect(_store.followOf(lunchThread), _muted);
  });
}

late ThreadAccount _account;

ThreadUnreadStore get _store => _account.threadUnread;

const _notFollowed = ThreadFollow(isFollowing: false, isMuted: false);
const _followed = ThreadFollow(isFollowing: true, isMuted: false);
const _muted = ThreadFollow(isFollowing: true, isMuted: true);
