import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/network_connection_service.dart';

void main() {
  group('ConnectivityResultsExtension.primary', () {
    test('is none without any result', () {
      expect(<ConnectivityResult>[].primary, ConnectivityResult.none);
    });

    test('is none when the only result is none', () {
      expect([ConnectivityResult.none].primary, ConnectivityResult.none);
    });

    test('is the first result of several', () {
      expect(
        [ConnectivityResult.wifi, ConnectivityResult.mobile].primary,
        ConnectivityResult.wifi,
      );
    });
  });
}
