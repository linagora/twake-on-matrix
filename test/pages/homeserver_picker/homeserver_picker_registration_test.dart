import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/homeserver_picker/homeserver_picker.dart';

class _FakeClient extends Fake implements Client {
  _FakeClient(this.onRegister);

  final Future<RegisterResponse> Function() onRegister;

  @override
  Future<RegisterResponse> register({
    String? deviceId,
    String? initialDeviceDisplayName,
    bool? refreshToken,
    String? password,
    String? username,
    AuthenticationData? auth,
    bool? inhibitLogin,
    AccountKind? kind,
    void Function(InitState)? onInitStateChanged,
  }) => onRegister();
}

void main() {
  group('HomeserverPickerController.supportsRegistration', () {
    test('a server that registers without more steps supports it', () async {
      // Arrange
      final client = _FakeClient(
        () async => RegisterResponse(userId: '@new:example.org'),
      );

      // Act
      final result = await HomeserverPickerController.supportsRegistration(
        client,
      );

      // Assert
      expect(result, isTrue);
    });

    test('a server that asks for more auth stages supports it', () async {
      // Arrange
      final client = _FakeClient(
        () => throw MatrixException.fromJson({
          'flows': [
            {
              'stages': ['m.login.dummy'],
            },
          ],
          'session': 'abc',
        }),
      );

      // Act
      final result = await HomeserverPickerController.supportsRegistration(
        client,
      );

      // Assert
      expect(result, isTrue);
    });

    test('a server that refuses registration does not support it', () async {
      // Arrange
      final client = _FakeClient(
        () => throw MatrixException.fromJson({
          'errcode': 'M_FORBIDDEN',
          'error': 'Registration is disabled',
        }),
      );

      // Act
      final result = await HomeserverPickerController.supportsRegistration(
        client,
      );

      // Assert
      expect(result, isFalse);
    });

    test('a failing check does not support registration', () async {
      // Arrange
      final client = _FakeClient(() => throw Exception('offline'));

      // Act
      final result = await HomeserverPickerController.supportsRegistration(
        client,
      );

      // Assert
      expect(result, isFalse);
    });
  });
}
