import 'package:flutter_test/flutter_test.dart';

import '../base/api_login_helper.dart';
import '../base/base_test_scenario.dart';
import '../base/mobile_group_fixture.dart';
import '../robots/thread_robot.dart';
import 'thread_scenarios.dart';

/// Patrol scenarios of threads, P2 "Suivre, muet, résolu"
/// (docs/plan/2026-11-06-threads-mobile-spec.md, THR-M-07, 08, 09 and § 4).
///
/// The receiver posts the threads; "the web" is another session of the
/// primary account, which reads and writes what Twake Chat web does:
/// `app.twake.chat.thread_prefs`, the override push rule
/// `app.twake.chat.thread.<rootId>` and the state
/// `app.twake.chat.thread_resolved`.

const _prefsType = 'app.twake.chat.thread_prefs';
const _resolvedType = 'app.twake.chat.thread_resolved';

const _follow = 'Follow the thread';
const _unfollow = 'Unfollow the thread';
const _mute = 'Mute the thread';
const _unmute = 'Unmute the thread';
const _resolve = 'Mark as resolved';
const _reopen = 'Reopen the thread';

/// A thread of the receiver, open on screen.
class _OpenThread {
  const _OpenThread(this.fixture, this.ids, this.lastReply);

  final MobileGroupFixture fixture;
  final ({String rootId, String replyId}) ids;
  final ThreadText lastReply;

  String get roomId => fixture.roomId;

  String get rootId => ids.rootId;

  /// The choice the server holds for this thread, as the web reads it.
  Future<String?> savedPref() async {
    final content = await fetchAccountDataAsPrimary(_prefsType);
    final threads = (content?['threads'] as List?) ?? const [];
    final entry = threads.whereType<Map>().where(
      (entry) => entry['roomId'] == roomId && entry['threadId'] == rootId,
    );
    return entry.isEmpty ? null : entry.first['pref'] as String?;
  }

  Future<Map<String, dynamic>?> muteRule() =>
      fetchOverrideRuleAsPrimary('app.twake.chat.thread.$rootId');

  /// The web of the same user mutes the thread. Only its account data is
  /// written here: it is what the mobile reads.
  Future<void> mutedOnTheWeb() => putAccountDataAsPrimary(
    type: _prefsType,
    content: {
      'threads': [
        {'roomId': roomId, 'threadId': rootId, 'pref': 'mute'},
      ],
    },
  );

  Future<void> resolvedOnTheWeb() => sendStateAsPrimary(
    roomId: roomId,
    eventType: _resolvedType,
    stateKey: rootId,
    content: {'resolved': true},
  );
}

/// Opens the room, has the receiver post a thread, opens it from its card.
Future<_OpenThread> _openReceivedThread(BaseTestScenario scenario) async {
  final fixture = await openMobileGroupFixture(scenario);
  final uid = threadUid();
  final root = ThreadText('prefs root $uid');
  final reply = ThreadText('prefs reply $uid');
  final ids = await receiverThread(
    roomId: fixture.roomId,
    root: root,
    reply: reply,
  );
  await waitForThreadMessage(scenario, root);
  await ThreadRobot(scenario.$).openFromCard(lastReply: reply);
  return _OpenThread(fixture, ids, reply);
}

/// The server answers a write after a moment: polls what it holds.
Future<void> _eventually(
  BaseTestScenario scenario,
  Future<bool> Function() holds, {
  required String reason,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (!await holds()) {
    if (DateTime.now().isAfter(deadline)) fail(reason);
    await scenario.$.pump(const Duration(seconds: 1));
  }
}

/// THR-M-07, § 4: following and unfollowing from the « ⋮ » menu writes the
/// shared account data, and the menu follows the choice.
class FollowFromMenuScenario extends BaseTestScenario {
  FollowFromMenuScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final threads = ThreadRobot($);
    final thread = await _openReceivedThread(this);

    await threads.expectThreadMenuOffers([_follow]);
    await threads.chooseInThreadMenu(_follow);
    await _eventually(
      this,
      () async => await thread.savedPref() == 'follow',
      reason: 'The web must read « follow » for the thread',
    );
    await threads.expectThreadMenuOffers([_unfollow, _mute]);

    await threads.chooseInThreadMenu(_unfollow);
    await _eventually(
      this,
      () async => await thread.savedPref() == 'unfollow',
      reason: 'The web must read « unfollow » for the thread',
    );
    await threads.expectThreadMenuOffers([_follow]);
  }
}

/// THR-M-07, THR-M-09, § 4: muting adds the server push rule of the web, so
/// no device notifies; unmuting removes it.
class MuteFromMenuScenario extends BaseTestScenario {
  MuteFromMenuScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final threads = ThreadRobot($);
    final thread = await _openReceivedThread(this);
    await threads.sendInThread(ThreadText('I am in ${thread.rootId}'));

    await threads.chooseInThreadMenu(_mute);
    await _eventually(
      this,
      () async => await thread.savedPref() == 'mute',
      reason: 'The web must read « mute » for the thread',
    );
    final rule = await thread.muteRule();
    expect(rule, isNotNull, reason: 'The server must hold the mute rule');
    expect(rule!['actions'], isEmpty, reason: 'A muted thread never notifies');
    await threads.expectThreadMenuOffers([_unfollow, _unmute]);

    await threads.chooseInThreadMenu(_unmute);
    await _eventually(
      this,
      () async => await thread.muteRule() == null,
      reason: 'Unmuting must remove the push rule of the thread',
    );
    expect(await thread.savedPref(), 'follow');
  }
}

/// THR-M-08, THR-M-02: resolving from the menu checks the header and the
/// card; reopening takes the check off.
class ResolveFromMenuScenario extends BaseTestScenario {
  ResolveFromMenuScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final threads = ThreadRobot($);
    final thread = await _openReceivedThread(this);

    await threads.chooseInThreadMenu(_resolve);
    await threads.expectResolvedInHeader();
    await threads.expectThreadMenuOffers([_reopen]);

    await threads.closeThread();
    await threads.expectResolvedOnCard(lastReply: thread.lastReply);

    await threads.openFromCard(lastReply: thread.lastReply);
    await threads.chooseInThreadMenu(_reopen);
    await threads.expectNotResolvedInHeader();
  }
}

/// THR-M-07, THR-M-08: a choice and a resolve made on the web apply on the
/// mobile, the thread still open, without restarting the app.
class WebChoiceAppliesScenario extends BaseTestScenario {
  WebChoiceAppliesScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final threads = ThreadRobot($);
    final thread = await _openReceivedThread(this);
    await threads.expectThreadMenuOffers([_follow]);

    await thread.mutedOnTheWeb();
    await $.pump(const Duration(seconds: 5));
    await threads.expectThreadMenuOffers([_unfollow, _unmute]);

    await thread.resolvedOnTheWeb();
    await threads.expectResolvedInHeader();

    await threads.closeThread();
    await threads.expectResolvedOnCard(lastReply: thread.lastReply);
  }
}
