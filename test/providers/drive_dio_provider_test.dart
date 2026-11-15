import 'package:twake_chat/data/drive/sources/drive_dio.provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('driveDioProvider', () {
    test('waits up to 120 s for a slow SSO or Drive stack', () {
      final container = ProviderContainer.test(retry: (_, _) => null);

      final options = container.read(driveDioProvider).options;

      expect(options.connectTimeout, const Duration(seconds: 120));
      expect(options.receiveTimeout, const Duration(seconds: 120));
    });
  });
}
