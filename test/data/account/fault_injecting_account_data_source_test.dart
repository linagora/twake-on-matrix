import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

import 'fakes.dart';
import 'fault_injecting_account_data_source.dart';

void main() {
  late FakeAccountClientDataSource inner;

  setUp(() => inner = FakeAccountClientDataSource());

  const names = ['a', 'b'];
  const expectedCallsBySucceedFirst = {
    0: ['add:a'],
    1: ['add:a', 'add:b'],
  };

  for (final entry in expectedCallsBySucceedFirst.entries) {
    final succeedFirst = entry.key;

    test('lets $succeedFirst addClientName calls through, fails the next one '
        'once when armed, then delegates', () async {
      final source = FaultInjectingAccountDataSource(
        inner,
        failAddClientNameOnce: true,
        succeedFirst: succeedFirst,
      );

      for (final name in names.take(succeedFirst)) {
        await source.addClientName(name);
      }
      final armedName = names[succeedFirst];
      await expectLater(source.addClientName(armedName), throwsStateError);
      await source.addClientName(armedName);

      expect(inner.calls, entry.value);
    });
  }

  test('does not fail when not armed', () async {
    final source = FaultInjectingAccountDataSource(
      inner,
      failAddClientNameOnce: false,
    );

    await source.addClientName('a');

    expect(inner.calls, ['add:a']);
  });

  test('is disarmed by default', () async {
    final source = FaultInjectingAccountDataSource(inner);

    await source.addClientName('a');

    expect(inner.calls, ['add:a']);
  });

  test('everything else goes straight to the real source', () async {
    final source = FaultInjectingAccountDataSource(
      inner,
      failAddClientNameOnce: true,
    );
    final client = await source.createClient('c');

    await source.removeClientName('c');
    await source.disposeAndDeleteStorage(client);

    expect(inner.calls, ['create:c', 'remove:c', 'delete:c']);
  });

  group('disposeAndDeleteStorage keeps the stages of the wrapped source', () {
    late FaultInjectingAccountDataSource source;
    late Client client;

    setUp(() async {
      source = FaultInjectingAccountDataSource(
        inner,
        failAddClientNameOnce: true,
      );
      client = await source.createClient('c');
    });

    test(
      'a failure is reported and a retry reaches the wrapped source',
      () async {
        inner.failDelete = true;
        await expectLater(
          source.disposeAndDeleteStorage(client),
          throwsStateError,
        );
        inner.failDelete = false;

        await source.disposeAndDeleteStorage(client);

        expect(inner.calls, ['create:c', 'delete:c', 'delete:c']);
      },
    );

    test('the same client reaches the wrapped source every time', () async {
      final other = await source.createClient('d');

      await source.disposeAndDeleteStorage(client);
      await source.disposeAndDeleteStorage(other);
      await source.disposeAndDeleteStorage(client);

      expect(inner.calls, [
        'create:c',
        'create:d',
        'delete:c',
        'delete:d',
        'delete:c',
      ]);
    });
  });
}
