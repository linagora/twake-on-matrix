import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';
import 'package:twake_chat/providers/person_presence_provider.dart';

import 'fake_active_account.dart';

const _alice = '@alice:server';

class _Account extends Fake implements Client {
  _Account(this.userID, this.alicePresence);

  @override
  final String userID;
  final PresenceType alicePresence;

  @override
  final onPresenceChanged = CachedStreamController<CachedPresence>();

  @override
  Future<CachedPresence> fetchCurrentPresence(
    String userId, {
    bool fetchOnlyFromCached = false,
  }) async => CachedPresence.neverSeen(userId);

  int serverReads = 0;

  @override
  Future<GetPresenceResponse> getPresence(String userId) async {
    serverReads++;
    return GetPresenceResponse(presence: alicePresence);
  }
}

void main() {
  test('follows the account that becomes active', () async {
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: activeAccountOverridesFollowing(),
    );
    final values = <PresenceStatus?>[];
    container.listen(
      personPresenceProvider(_alice),
      (_, next) => next.whenData((presence) => values.add(presence?.status)),
      fireImmediately: true,
    );
    await pumpEventQueue();

    container
        .read(fakeActiveAccountProvider.notifier)
        .set(_Account('@me:one', PresenceType.online));
    await pumpEventQueue();
    container
        .read(fakeActiveAccountProvider.notifier)
        .set(_Account('@me:two', PresenceType.unavailable));
    await pumpEventQueue();

    expect(values, [null, PresenceStatus.online, PresenceStatus.away]);
  });

  test('the list presence never asks the server', () async {
    final account = _Account('@me:one', PresenceType.online);
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: activeAccountOverridesFollowing(),
    );
    container.read(fakeActiveAccountProvider.notifier).set(account);
    final values = <PresenceStatus?>[];
    container.listen(
      syncedPersonPresenceProvider(_alice),
      (_, next) => next.whenData((presence) => values.add(presence?.status)),
      fireImmediately: true,
    );
    await pumpEventQueue();

    expect(values, [PresenceStatus.offline]);
    expect(account.serverReads, 0);
  });
}
