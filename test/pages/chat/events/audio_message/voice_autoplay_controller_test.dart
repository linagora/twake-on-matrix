import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/data/voice_message/repositories/voice_message_repository.provider.dart';
import 'package:twake_chat/domain/voice_message/exceptions/voice_message_exception.dart';
import 'package:twake_chat/domain/voice_message/repositories/voice_message_repository.dart';
import 'package:twake_chat/pages/chat/events/audio_message/voice_autoplay_controller.dart';
import 'package:twake_chat/providers/report_failure_provider.dart';

const _roomId = '!room:example.org';

class _Repository implements VoiceMessageRepository {
  final next = <String, String?>{};
  final asked = <String>[];
  final threads = <String?>[];
  final gates = <String, Completer<void>>{};
  Completer<void>? gate;
  Object? error;

  @override
  Future<String?> nextVoiceMessageId({
    required String roomId,
    required String eventId,
    String? threadRootId,
  }) async {
    asked.add(eventId);
    threads.add(threadRootId);
    await gate?.future;
    await gates[eventId]?.future;
    if (error != null) throw error!;
    return next[eventId];
  }
}

void main() {
  late _Repository repository;
  late ProviderContainer container;
  late List<Object> failures;

  final provider = voiceAutoplayControllerProvider(_roomId, null);

  setUp(() {
    repository = _Repository();
    failures = [];
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        voiceMessageRepositoryProvider.overrideWithValue(repository),
        reportFailureProvider.overrideWithValue(
          (error, _, _) => failures.add(error),
        ),
      ],
    );
  });

  test('starts idle', () {
    container.listen(provider, (_, _) {});

    expect(container.read(provider), const VoiceAutoplayState.idle());
  });

  test('queues the next voice message when one ends', () async {
    repository.next['v1'] = 'v2';
    final states = <VoiceAutoplayState>[];
    container.listen(provider, (_, next) => states.add(next));

    await container.read(provider.notifier).voiceMessageEnded('v1');

    expect(repository.asked, ['v1']);
    expect(states.last, const VoiceAutoplayState.next('v2'));
  });

  test('queues each next message of the run', () async {
    repository.next.addAll({'v1': 'v2', 'v2': 'v3'});
    final states = <VoiceAutoplayState>[];
    container.listen(provider, (_, next) => states.add(next));
    final controller = container.read(provider.notifier);

    await controller.voiceMessageEnded('v1');
    await controller.voiceMessageEnded('v2');
    await controller.voiceMessageEnded('v3');

    expect(states, const [
      VoiceAutoplayState.next('v2'),
      VoiceAutoplayState.idle(),
      VoiceAutoplayState.next('v3'),
      VoiceAutoplayState.idle(),
    ]);
  });

  test('stays idle when the next message is not a voice message', () async {
    container.listen(provider, (_, _) {});

    await container.read(provider.notifier).voiceMessageEnded('v1');

    expect(container.read(provider), const VoiceAutoplayState.idle());
  });

  test('stops when the chat screen is left during the lookup', () async {
    repository
      ..next['v1'] = 'v2'
      ..gate = Completer();
    final sub = container.listen(provider, (_, _) {});
    final controller = container.read(provider.notifier);

    final ended = controller.voiceMessageEnded('v1');
    sub.close();
    await container.pump();
    repository.gate!.complete();

    await expectLater(ended, completes);
  });

  test('does nothing once the chat screen is left', () async {
    final sub = container.listen(provider, (_, _) {});
    final controller = container.read(provider.notifier);
    sub.close();
    await container.pump();

    await controller.voiceMessageEnded('v1');

    expect(repository.asked, isEmpty);
  });

  test('reports a failed lookup and stays idle', () async {
    repository.error = StateError('db');
    container.listen(provider, (_, _) {});

    await container.read(provider.notifier).voiceMessageEnded('v1');

    expect(failures.single, isA<FindNextVoiceMessageException>());
    expect(container.read(provider), const VoiceAutoplayState.idle());
  });

  test('looks up the next message in the thread of its screen', () async {
    final thread = voiceAutoplayControllerProvider(_roomId, r'$root');
    container.listen(thread, (_, _) {});

    await container.read(thread.notifier).voiceMessageEnded(r'$root');

    expect(repository.threads, [r'$root']);
  });

  test('drops the next message of a run that a newer one replaced', () async {
    repository
      ..next.addAll({'v1': 'v2', 'other': 'other-next'})
      ..gates['v1'] = Completer();
    final states = <VoiceAutoplayState>[];
    container.listen(provider, (_, next) => states.add(next));
    final controller = container.read(provider.notifier);

    final stale = controller.voiceMessageEnded('v1');
    await controller.voiceMessageEnded('other');
    repository.gates['v1']!.complete();
    await stale;

    expect(
      container.read(provider),
      const VoiceAutoplayState.next('other-next'),
    );
    expect(states, isNot(contains(const VoiceAutoplayState.next('v2'))));
  });
}
