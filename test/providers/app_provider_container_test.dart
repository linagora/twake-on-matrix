import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/providers/app_provider_container.dart';

void main() {
  test('a failing provider is not retried automatically', () async {
    var calls = 0;
    final failing = FutureProvider<void>((ref) async {
      calls++;
      throw Exception('boom');
    });
    final container = createAppProviderContainer();
    addTearDown(container.dispose);

    container.listen(failing, (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 500));

    expect(calls, 1);
    expect(container.read(failing).hasError, isTrue);
  });

  test('creating a new app container disposes the previous one', () {
    var isDisposed = false;
    final kept = Provider<int>((ref) {
      ref.onDispose(() => isDisposed = true);
      return 0;
    });
    createAppProviderContainer().read(kept);

    final next = createAppProviderContainer();
    addTearDown(next.dispose);

    expect(isDisposed, isTrue);
  });

  test('the overrides it is made with are applied', () {
    final value = Provider<int>((ref) => 1);
    final container = createAppProviderContainer(
      overrides: [value.overrideWithValue(7)],
    );
    addTearDown(container.dispose);

    expect(container.read(value), 7);
  });
}
