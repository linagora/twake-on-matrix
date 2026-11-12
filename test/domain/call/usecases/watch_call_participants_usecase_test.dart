import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/call/usecases/watch_call_participants_usecase.dart';

import '../fake_call_repository.dart';

void main() {
  test('execute_always_emitsTheParticipantsOfTheRepository', () async {
    // Arrange
    final repository = FakeCallRepository();
    final everyone = [participant('@me:hs.test:DEV', isLocal: true)];
    final next = WatchCallParticipantsUseCase(repository).execute('!r').first;

    // Act
    repository.participants.add(everyone);

    // Assert
    expect(await next, everyone);
  });
}
