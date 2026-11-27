import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/call/usecases/set_call_camera_usecase.dart';

import '../fake_call_repository.dart';

void main() {
  test('execute_always_setsTheCamera', () async {
    // Arrange
    final repository = FakeCallRepository();

    // Act
    await SetCallCameraUseCase(repository).execute(isOn: true);

    // Assert
    expect(repository.calls, ['camera true']);
  });
}
