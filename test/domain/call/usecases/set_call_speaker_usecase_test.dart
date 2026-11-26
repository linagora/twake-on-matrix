import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/call/usecases/set_call_speaker_usecase.dart';

import '../fake_call_repository.dart';

void main() {
  test('execute_always_setsTheSpeaker', () async {
    // Arrange
    final repository = FakeCallRepository();

    // Act
    await SetCallSpeakerUseCase(repository).execute(isOn: true, isForced: true);

    // Assert
    expect(repository.calls, ['speaker true forced=true']);
  });
}
