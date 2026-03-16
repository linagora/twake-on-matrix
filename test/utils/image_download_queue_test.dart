import 'package:fluffychat/utils/image_download_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ImageDownloadQueue queue;

  setUp(() {
    // Create a fresh instance for each test via the public constructor-like
    // pattern. Since the class is a singleton, we test through the singleton.
    // Reset by releasing all tickets between tests.
    queue = ImageDownloadQueue.instance;
  });

  test('acquire grants immediately when under maxConcurrent', () async {
    final tickets = <ImageDownloadTicket>[];
    for (var i = 0; i < ImageDownloadQueue.maxConcurrent; i++) {
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
    // Fill up all slots
    for (var i = 0; i < ImageDownloadQueue.maxConcurrent; i++) {
      final ticket = queue.acquire();
      tickets.add(ticket);
      await ticket.ready;
    }

    // This one should be queued
    final queuedTicket = queue.acquire();
    expect(queue.queuedCount, 1);

    // Should not resolve yet
    var resolved = false;
    queuedTicket.ready.then((_) => resolved = true);

    // Give it a microtask turn
    await Future.delayed(Duration.zero);
    expect(resolved, isFalse);

    // Release one slot
    queue.release(tickets.first);

    // Now the queued ticket should resolve
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

  test('cancel removes ticket from queue', () async {
    final tickets = <ImageDownloadTicket>[];
    // Fill up all slots
    for (var i = 0; i < ImageDownloadQueue.maxConcurrent; i++) {
      final ticket = queue.acquire();
      tickets.add(ticket);
      await ticket.ready;
    }

    // Queue two more
    final queued1 = queue.acquire();
    final queued2 = queue.acquire();
    expect(queue.queuedCount, 2);

    // Cancel the first queued one
    queued1.cancel();
    final result1 = await queued1.ready;
    expect(result1, isFalse);

    // Release a slot — queued2 should get it, not queued1
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

  test('release on active ticket decrements count', () async {
    final ticket = queue.acquire();
    await ticket.ready;
    expect(queue.activeCount, 1);

    queue.release(ticket);
    expect(queue.activeCount, 0);
  });

  test('release on queued ticket removes from queue', () async {
    final tickets = <ImageDownloadTicket>[];
    for (var i = 0; i < ImageDownloadQueue.maxConcurrent; i++) {
      final ticket = queue.acquire();
      tickets.add(ticket);
      await ticket.ready;
    }

    final queuedTicket = queue.acquire();
    expect(queue.queuedCount, 1);

    // Release the queued ticket (simulating dispose before grant)
    queue.release(queuedTicket);
    expect(queue.queuedCount, 0);

    final result = await queuedTicket.ready;
    expect(result, isFalse);

    // Clean up
    for (final t in tickets) {
      queue.release(t);
    }
    expect(queue.activeCount, 0);
  });

  test('FIFO order is respected', () async {
    final tickets = <ImageDownloadTicket>[];
    // Fill up all slots
    for (var i = 0; i < ImageDownloadQueue.maxConcurrent; i++) {
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

    // Release slots one by one
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
}
