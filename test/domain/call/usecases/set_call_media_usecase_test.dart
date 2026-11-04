import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/call/usecases/set_call_media_usecase.dart';

import '../fake_call_repository.dart';

void main() {
  test('changes only what it is given', () async {
    final repository = FakeCallRepository();

    await SetCallMediaUseCase(repository).execute(isCameraOn: true);

    expect(repository.calls, ['camera true']);
  });

  test('changes the microphone before the camera', () async {
    final repository = FakeCallRepository();

    await SetCallMediaUseCase(
      repository,
    ).execute(isMicrophoneOn: false, isCameraOn: false);

    expect(repository.calls, ['microphone false', 'camera false']);
  });
}
