import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/services/room_send_queue_service.dart';

void main() {
  group('RoomSendQueueService', () {
    const String roomId = '!room:example.org';
    late RoomSendQueueService service;

    setUp(() {
      service = RoomSendQueueService();
    });

    test('should return the result of the task', () async {
      // Act
      final String result = await service.enqueue(roomId, () async => 'done');

      // Assert
      expect(result, equals('done'));
    });

    test(
      'should not start a task while the previous one of the room is pending',
      () async {
        // Arrange
        final Completer<void> first = Completer<void>();
        final List<String> started = [];

        // Act
        final Future<void> firstTask = service.enqueue(roomId, () {
          started.add('first');
          return first.future;
        });
        final Future<void> secondTask = service.enqueue(roomId, () async {
          started.add('second');
        });
        await Future<void>.delayed(Duration.zero);
        final List<String> startedWhileFirstPending = List.of(started);
        first.complete();
        await Future.wait([firstTask, secondTask]);

        // Assert
        expect(startedWhileFirstPending, equals(['first']));
        expect(started, equals(['first', 'second']));
      },
    );

    test('should not make a room wait for another room', () async {
      // Arrange
      final Completer<void> first = Completer<void>();
      bool otherRoomStarted = false;

      // Act
      final Future<void> firstTask = service.enqueue(
        roomId,
        () => first.future,
      );
      await service.enqueue('!other:example.org', () async {
        otherRoomStarted = true;
      });

      // Assert
      expect(otherRoomStarted, isTrue);
      first.complete();
      await firstTask;
    });

    test('should give the error to the caller and run the next task', () async {
      // Arrange
      final Exception error = Exception('send failed');
      bool nextTaskStarted = false;

      // Act
      final Future<void> failingTask = service.enqueue<void>(
        roomId,
        () async => throw error,
      );
      final Future<void> nextTask = service.enqueue(roomId, () async {
        nextTaskStarted = true;
      });

      // Assert
      await expectLater(failingTask, throwsA(same(error)));
      await nextTask;
      expect(nextTaskStarted, isTrue);
    });
  });
}
