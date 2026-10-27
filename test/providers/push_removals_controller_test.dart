import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/account/repositories/account_repository.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/push_removals_controller.dart';
import 'package:matrix/matrix.dart';

import '../data/account/fakes.dart';

class _TokenClient extends FakeAccountClient {
  _TokenClient(super.clientName);

  @override
  String? get accessToken => 'token';
}

class _Repository extends Fake implements AccountRepository {
  final pending = <String>{};

  @override
  Future<void> markPushRemovalPending(String id) async => pending.add(id);

  @override
  Future<void> clearPushRemovalPending(String id) async => pending.remove(id);
}

class _Teardown implements PushTeardown {
  final removed = <String>[];
  final reported = <String>[];
  bool fail = false;

  @override
  bool isPushReady = true;

  @override
  Future<void> removePush(Client target) async {
    removed.add(target.clientName);
    if (fail) throw StateError('network');
  }

  @override
  void report(Object error, StackTrace stackTrace, String what) =>
      reported.add(what);
}

void main() {
  late ProviderContainer container;
  late _Repository repository;
  late _Teardown teardown;

  PushRemovalsController controller() =>
      container.read(pushRemovalsControllerProvider.notifier);

  setUp(() {
    repository = _Repository();
    teardown = _Teardown();
    container = ProviderContainer(
      overrides: [accountRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  test('without a teardown nothing is removed', () async {
    await controller().removeBeforeLogout(_TokenClient('a'));

    expect(teardown.removed, isEmpty);
    expect(repository.pending, isEmpty);
  });

  test('removes the push of the client through the teardown set', () async {
    controller().setTeardown(teardown);

    await controller().removeBeforeLogout(_TokenClient('a'));

    expect(teardown.removed, ['a']);
    expect(repository.pending, isEmpty);
  });

  test('a failed deletion is reported and kept as pending', () async {
    controller().setTeardown(teardown);
    teardown.fail = true;

    await controller().removeBeforeLogout(_TokenClient('a'));

    expect(teardown.reported, isNotEmpty);
    expect(repository.pending, {'a'});
  });

  test('clears only the teardown still set', () {
    final other = _Teardown();
    controller().setTeardown(teardown);

    controller().clearTeardown(other);
    expect(container.read(pushRemovalsControllerProvider), same(teardown));

    controller().clearTeardown(teardown);
    expect(container.read(pushRemovalsControllerProvider), isNull);
  });
}
