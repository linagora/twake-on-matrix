import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/account/datasources_impl/fault_injecting_account_data_source.dart';

import 'fakes.dart';

void main() {
  late FakeAccountClientDataSource inner;

  setUp(() => inner = FakeAccountClientDataSource());

  test('fails addClientName once when armed, then delegates', () async {
    final source = FaultInjectingAccountDataSource(
      inner,
      failAddClientNameOnce: true,
    );

    await expectLater(source.addClientName('a'), throwsStateError);
    await source.addClientName('a');

    expect(inner.calls, ['add:a']);
  });

  test('lets the first calls through when asked to', () async {
    final source = FaultInjectingAccountDataSource(
      inner,
      failAddClientNameOnce: true,
      succeedFirst: 1,
    );

    await source.addClientName('a');
    await expectLater(source.addClientName('b'), throwsStateError);
    await source.addClientName('b');

    expect(inner.calls, ['add:a', 'add:b']);
  });

  test('does not fail when not armed', () async {
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
    await source.loadClients(initialize: false);

    expect(inner.calls, ['create:c', 'remove:c', 'delete:c', 'load']);
  });
}
