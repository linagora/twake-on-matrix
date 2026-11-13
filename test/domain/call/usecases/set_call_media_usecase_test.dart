import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/call/usecases/set_call_media_usecase.dart';

import '../fake_call_repository.dart';

void main() {
  test('execute_always_setsTheMicrophone', () async {
    // Arrange
    final repository = FakeCallRepository();

    // Act
    await SetCallMediaUseCase(repository).execute(isMicrophoneOn: false);

    // Assert
    expect(repository.calls, ['microphone false']);
  });
}
