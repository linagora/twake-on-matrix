import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.provider.dart';
import 'package:twake_chat/providers/twake_supported_provider.dart';

void main() {
  late DynamicUrlInterceptors interceptor;
  late ProviderContainer container;

  setUp(() {
    interceptor = DynamicUrlInterceptors();
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        tomServerUrlInterceptorProvider.overrideWithValue(interceptor),
      ],
    );
  });

  test('no ToM base url: not supported', () {
    expect(container.read(twakeSupportedProvider), isFalse);
  });

  test('ToM base url already set: supported', () {
    interceptor.changeBaseUrl('https://tom.example.com/');

    expect(container.read(twakeSupportedProvider), isTrue);
  });

  test('watchers follow the ToM base url as it is set and cleared', () async {
    final seen = <bool>[];
    container.listen(
      twakeSupportedProvider,
      (_, next) => seen.add(next),
      fireImmediately: true,
    );

    interceptor.changeBaseUrl('https://tom.example.com/');
    await container.pump();
    interceptor.changeBaseUrl(null);
    await container.pump();

    expect(seen, [false, true, false]);
  });

  test('the same ToM base url again: the provider does not rebuild', () async {
    final counting = _CountingInterceptor()
      ..changeBaseUrl('https://tom.example.com/');
    final countingContainer = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [tomServerUrlInterceptorProvider.overrideWithValue(counting)],
    );
    countingContainer.listen(twakeSupportedProvider, (_, _) {});
    expect(counting.builds, 1);

    counting.changeBaseUrl('https://tom.example.com/');
    await countingContainer.pump();
    expect(counting.builds, 1);

    counting.changeBaseUrl('https://other.example.com/');
    await countingContainer.pump();
    expect(counting.builds, 2);
  });
}

/// The provider reads [baseUrlListenable] once per build.
class _CountingInterceptor extends DynamicUrlInterceptors {
  int builds = 0;

  @override
  ValueListenable<String?> get baseUrlListenable {
    builds++;
    return super.baseUrlListenable;
  }
}
