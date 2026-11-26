import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/data/voice_message/repositories/voice_message_repository.provider.dart';
import 'package:twake_chat/domain/voice_message/entities/shown_message.dart';
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
    if (error case final error?) throw error;
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

  ShownMessage voice(String id) =>
      ShownMessage(eventId: id, isVoiceMessage: true);
  ShownMessage text(String id) =>
      ShownMessage(eventId: id, isVoiceMessage: false);

  test('starts idle', () {
    container.listen(provider, (_, _) {});

    expect(container.read(provider), const VoiceAutoplayState.idle());
  });

  test('asks the screen what it shows when a voice message ends', () {
    final states = <VoiceAutoplayState>[];
    container.listen(provider, (_, next) => states.add(next));
    final controller = container.read(provider.notifier);

    controller.voiceMessageEnded('v1');
    controller.voiceMessageEnded('v1');

    expect(states, const [
      VoiceAutoplayState.ended('v1', 1),
      VoiceAutoplayState.ended('v1', 2),
    ]);
  });

  test('takes the next voice message from what the screen shows', () async {
    repository.next['v1'] = 'stored';
    container.listen(provider, (_, _) {});
    final controller = container.read(provider.notifier)
      ..voiceMessageEnded('v1');

    await controller.findNext('v1', shown: [voice('v1'), voice('v2')]);

    expect(container.read(provider), const VoiceAutoplayState.next('v2'));
    expect(repository.asked, isEmpty);
  });

  test(
    'stops at a message of the screen that is not a voice message',
    () async {
      container.listen(provider, (_, _) {});
      final controller = container.read(provider.notifier)
        ..voiceMessageEnded('v1');

      await controller.findNext(
        'v1',
        shown: [voice('v1'), text('t'), voice('v2')],
      );

      expect(container.read(provider), const VoiceAutoplayState.idle());
    },
  );

  test('stops after the last message of the screen', () async {
    container.listen(provider, (_, _) {});
    final controller = container.read(provider.notifier)
      ..voiceMessageEnded('v2');

    await controller.findNext('v2', shown: [voice('v1'), voice('v2')]);

    expect(container.read(provider), const VoiceAutoplayState.idle());
    expect(repository.asked, isEmpty);
  });

  test('reads the store when the screen does not show the message', () async {
    repository.next['v1'] = 'v2';
    container.listen(provider, (_, _) {});
    final controller = container.read(provider.notifier)
      ..voiceMessageEnded('v1');

    await controller.findNext('v1', shown: [voice('other')]);

    expect(repository.asked, ['v1']);
    expect(container.read(provider), const VoiceAutoplayState.next('v2'));
  });

  test('reads the store in the thread of its screen', () async {
    final thread = voiceAutoplayControllerProvider(_roomId, r'$root');
    container.listen(thread, (_, _) {});
    final controller = container.read(thread.notifier)
      ..voiceMessageEnded(r'$root');

    await controller.findNext(r'$root', shown: const []);

    expect(repository.threads, [r'$root']);
  });

  test('stops when the chat screen is left during the lookup', () async {
    repository
      ..next['v1'] = 'v2'
      ..gate = Completer();
    final sub = container.listen(provider, (_, _) {});
    final controller = container.read(provider.notifier)
      ..voiceMessageEnded('v1');

    final lookup = controller.findNext('v1', shown: const []);
    sub.close();
    await container.pump();
    repository.gate!.complete();

    await expectLater(lookup, completes);
  });

  test('does nothing once the chat screen is left', () async {
    final sub = container.listen(provider, (_, _) {});
    final controller = container.read(provider.notifier);
    sub.close();
    await container.pump();

    controller.voiceMessageEnded('v1');
    await controller.findNext('v1', shown: const []);

    expect(repository.asked, isEmpty);
  });

  test('drops the next message of a run that a newer one replaced', () async {
    repository
      ..next.addAll({'v1': 'v2', 'other': 'other-next'})
      ..gates['v1'] = Completer();
    final states = <VoiceAutoplayState>[];
    container.listen(provider, (_, next) => states.add(next));
    final controller = container.read(provider.notifier)
      ..voiceMessageEnded('v1');

    final stale = controller.findNext('v1', shown: const []);
    controller.voiceMessageEnded('other');
    await controller.findNext('other', shown: const []);
    repository.gates['v1']!.complete();
    await stale;

    expect(
      container.read(provider),
      const VoiceAutoplayState.next('other-next'),
    );
    expect(states, isNot(contains(const VoiceAutoplayState.next('v2'))));
  });

  test('reports a failed lookup and stays idle', () async {
    repository.error = Exception('db');
    container.listen(provider, (_, _) {});
    final controller = container.read(provider.notifier)
      ..voiceMessageEnded('v1');

    await controller.findNext('v1', shown: const []);

    expect(failures.single, isA<FindNextVoiceMessageException>());
    expect(container.read(provider), const VoiceAutoplayState.idle());
  });
}
