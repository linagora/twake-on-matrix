import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/call/usecases/watch_call_participants_usecase.dart';

import '../fake_call_repository.dart';

void main() {
  test('emits the participants of the repository', () async {
    final repository = FakeCallRepository();
    final everyone = [participant('@me:hs.test:DEV', isLocal: true)];

    final next = WatchCallParticipantsUseCase(repository).execute().first;
    repository.participants.add(everyone);

    expect(await next, everyone);
  });
}
