import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:twake_chat/data/direct_chat/datasources_impl/ignored_users_datasource_impl.dart';

class _FakeClient extends Fake implements Client {
  @override
  List<String> ignoredUsers = [];

  @override
  final onSync = CachedStreamController<SyncUpdate>();
}

SyncUpdate _accountDataSync(String type) => SyncUpdate(
  nextBatch: '',
  accountData: [BasicEvent(type: type, content: const {})],
);

void main() {
  const alice = '@alice:server';
  late _FakeClient client;
  late List<bool> values;

  setUp(() {
    client = _FakeClient();
    values = [];
  });

  Future<StreamSubscription<bool>> watch() async {
    final subscription = IgnoredUsersDatasourceImpl(
      client,
    ).watchIsIgnored(alice).listen(values.add);
    await pumpEventQueue();
    return subscription;
  }

  test('emits the current value first', () async {
    client.ignoredUsers = [alice];
    final subscription = await watch();
    addTearDown(subscription.cancel);

    expect(values, [true]);
  });

  test('re-reads the list when the ignored user list changes', () async {
    final subscription = await watch();
    addTearDown(subscription.cancel);

    client.ignoredUsers = [alice];
    client.onSync.add(_accountDataSync('m.ignored_user_list'));
    await pumpEventQueue();

    expect(values, [false, true]);
  });

  test('ignores other account data', () async {
    final subscription = await watch();
    addTearDown(subscription.cancel);

    client.ignoredUsers = [alice];
    client.onSync.add(_accountDataSync('m.direct'));
    await pumpEventQueue();

    expect(values, [false]);
  });

  test('is not ignored without an active client', () async {
    final values = await const IgnoredUsersDatasourceImpl(
      null,
    ).watchIsIgnored(alice).toList();

    expect(values, [false]);
  });
}
