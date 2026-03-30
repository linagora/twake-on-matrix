import 'package:fluffychat/utils/image_download_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ImageDownloadQueue queue;

  setUp(() {
    // Each test gets an isolated queue instance — no shared singleton state.
    queue = ImageDownloadQueue.forTesting(maxConcurrent: 4);
  });

  group('basic acquire/release', () {
    test('acquire grants immediately when under maxConcurrent', () async {
      final tickets = <ImageDownloadTicket>[];
      for (var i = 0; i < queue.maxConcurrent; i++) {
        final ticket = queue.acquire();
        tickets.add(ticket);
        final result = await ticket.ready;
        expect(result, isTrue);
        expect(ticket.isActive, isTrue);
      }

      // Clean up
      for (final t in tickets) {
        queue.release(t);
      }
      expect(queue.activeCount, 0);
    });

    test('acquire queues when at maxConcurrent', () async {
      final tickets = <ImageDownloadTicket>[];
      for (var i = 0; i < queue.maxConcurrent; i++) {
        final ticket = queue.acquire();
        tickets.add(ticket);
        await ticket.ready;
      }

      final queuedTicket = queue.acquire();
      expect(queue.queuedCount, 1);

      var resolved = false;
      queuedTicket.ready.then((_) => resolved = true);
      await Future.delayed(Duration.zero);
      expect(resolved, isFalse);

      queue.release(tickets.first);
      final result = await queuedTicket.ready;
      expect(result, isTrue);
      expect(queuedTicket.isActive, isTrue);

      // Clean up
      queue.release(queuedTicket);
      for (var i = 1; i < tickets.length; i++) {
        queue.release(tickets[i]);
      }
      expect(queue.activeCount, 0);
    });

    test('release on active ticket decrements count', () async {
      final ticket = queue.acquire();
      await ticket.ready;
      expect(queue.activeCount, 1);

      queue.release(ticket);
      expect(queue.activeCount, 0);
    });

    test('release on queued ticket cancels it', () async {
      final tickets = <ImageDownloadTicket>[];
      for (var i = 0; i < queue.maxConcurrent; i++) {
        final ticket = queue.acquire();
        tickets.add(ticket);
        await ticket.ready;
      }

      final queuedTicket = queue.acquire();
      expect(queue.queuedCount, 1);

      queue.release(queuedTicket);

      final result = await queuedTicket.ready;
      expect(result, isFalse);

      // Clean up
      for (final t in tickets) {
        queue.release(t);
      }
      expect(queue.activeCount, 0);
    });
  });

  group('cancel', () {
    test('cancel removes ticket from queue', () async {
      final tickets = <ImageDownloadTicket>[];
      for (var i = 0; i < queue.maxConcurrent; i++) {
        final ticket = queue.acquire();
        tickets.add(ticket);
        await ticket.ready;
      }

      final queued1 = queue.acquire();
      final queued2 = queue.acquire();
      expect(queue.queuedCount, 2);

      queued1.cancel();
      final result1 = await queued1.ready;
      expect(result1, isFalse);

      queue.release(tickets.first);
      final result2 = await queued2.ready;
      expect(result2, isTrue);

      // Clean up
      queue.release(queued2);
      for (var i = 1; i < tickets.length; i++) {
        queue.release(tickets[i]);
      }
      expect(queue.activeCount, 0);
    });
  });

  group('FIFO ordering', () {
    test('FIFO order is respected', () async {
      final tickets = <ImageDownloadTicket>[];
      for (var i = 0; i < queue.maxConcurrent; i++) {
        final ticket = queue.acquire();
        tickets.add(ticket);
        await ticket.ready;
      }

      final order = <int>[];
      final queued1 = queue.acquire();
      final queued2 = queue.acquire();
      final queued3 = queue.acquire();

      queued1.ready.then((_) => order.add(1));
      queued2.ready.then((_) => order.add(2));
      queued3.ready.then((_) => order.add(3));

      queue.release(tickets[0]);
      await Future.delayed(Duration.zero);
      queue.release(tickets[1]);
      await Future.delayed(Duration.zero);
      queue.release(tickets[2]);
      await Future.delayed(Duration.zero);

      expect(order, [1, 2, 3]);

      // Clean up
      queue.release(queued1);
      queue.release(queued2);
      queue.release(queued3);
      for (var i = 3; i < tickets.length; i++) {
        queue.release(tickets[i]);
      }
    });
  });

  group('starvation prevention', () {
    test(
      'reacquire without releasing previous queued ticket does not leak slots',
      () async {
        final queue = ImageDownloadQueue.forTesting(maxConcurrent: 2);

        final t1 = queue.acquire();
        final t2 = queue.acquire();
        await t1.ready;
        await t2.ready;

        final orphan = queue.acquire();
        expect(queue.queuedCount, 1);

        orphan.cancel();
        final replacement = queue.acquire();

        queue.release(t1);
        await Future.delayed(Duration.zero);

        final result = await replacement.ready;
        expect(result, isTrue);
        expect(queue.activeCount, 2);

        queue.release(t2);
        queue.release(replacement);
        expect(queue.activeCount, 0);
        expect(queue.queuedCount, 0);
      },
    );

    test(
      'orphaned granted ticket that is never released causes starvation',
      () async {
        final queue = ImageDownloadQueue.forTesting(maxConcurrent: 1);

        final t1 = queue.acquire();
        await t1.ready;
        expect(queue.activeCount, 1);

        final t2 = queue.acquire();
        expect(queue.queuedCount, 1);

        var t2Resolved = false;
        t2.ready.then((_) => t2Resolved = true);
        await Future.delayed(Duration.zero);
        expect(t2Resolved, isFalse);

        queue.release(t1);
        await Future.delayed(Duration.zero);
        expect(t2Resolved, isTrue);

        queue.release(t2);
        expect(queue.activeCount, 0);
      },
    );
  });

  group('stress test', () {
    test(
      'rapid acquire/cancel cycles leave queue in clean state',
      () async {
        final queue = ImageDownloadQueue.forTesting(maxConcurrent: 3);

        final holders = <ImageDownloadTicket>[];
        for (var i = 0; i < queue.maxConcurrent; i++) {
          final t = queue.acquire();
          await t.ready;
          holders.add(t);
        }

        for (var i = 0; i < 50; i++) {
          final ticket = queue.acquire();
          ticket.cancel();
          await ticket.ready;
        }

        for (final t in holders) {
          queue.release(t);
        }

        expect(queue.activeCount, 0);
        expect(queue.queuedCount, 0);
      },
    );

    test(
      'acquire-release cycle with full throughput',
      () async {
        final queue = ImageDownloadQueue.forTesting(maxConcurrent: 2);

        for (var i = 0; i < 20; i++) {
          final ticket = queue.acquire();
          final granted = await ticket.ready;
          expect(granted, isTrue);
          queue.release(ticket);
        }

        expect(queue.activeCount, 0);
        expect(queue.queuedCount, 0);
      },
    );
  });

  group('configurable maxConcurrent', () {
    test('respects custom maxConcurrent', () async {
      final smallQueue = ImageDownloadQueue.forTesting(maxConcurrent: 1);

      final t1 = smallQueue.acquire();
      await t1.ready;
      expect(smallQueue.activeCount, 1);

      final t2 = smallQueue.acquire();
      expect(smallQueue.queuedCount, 1);

      var t2Resolved = false;
      t2.ready.then((_) => t2Resolved = true);
      await Future.delayed(Duration.zero);
      expect(t2Resolved, isFalse);

      smallQueue.release(t1);
      await Future.delayed(Duration.zero);
      expect(t2Resolved, isTrue);

      smallQueue.release(t2);
      expect(smallQueue.activeCount, 0);
    });
  });

  group('singleton management', () {
    test('resetInstance creates a fresh queue', () {
      ImageDownloadQueue.instance.acquire();
      expect(ImageDownloadQueue.instance.activeCount, 1);

      ImageDownloadQueue.resetInstance();
      expect(ImageDownloadQueue.instance.activeCount, 0);
    });

    test('instance setter allows injection', () {
      final custom = ImageDownloadQueue.forTesting(maxConcurrent: 1);
      ImageDownloadQueue.instance = custom;
      expect(ImageDownloadQueue.instance.maxConcurrent, 1);

      ImageDownloadQueue.resetInstance();
    });
  });
}
