import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:twake_chat/data/drive/sources/web_auth_launcher.dart';

void main() {
  const channel = MethodChannel('flutter_web_auth_2');

  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('Drive sign-in uses an ephemeral browser session', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'authenticate');
          final arguments = call.arguments as Map<dynamic, dynamic>;
          final options = arguments['options'] as Map<dynamic, dynamic>;
          expect(options['preferEphemeral'], isTrue);
          expect(options['intentFlags'], ephemeralIntentFlags);
          return 'twake.chat://redirect/drive-sso?code=x';
        });

    final callback = await const FlutterWebAuth2Launcher().authenticate(
      url: 'https://sso.example/authorize',
      callbackScheme: 'twake.chat',
    );

    expect(callback, 'twake.chat://redirect/drive-sso?code=x');
  });
}
