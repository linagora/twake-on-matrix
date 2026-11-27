import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/utils/image_download_queue.dart';
import 'package:twake_chat/widgets/mxc_image.dart';

class _CountingQueue implements ImageDownloadQueue {
  final ImageDownloadQueue _queue = ImageDownloadQueue.forTesting();
  int acquired = 0;

  @override
  int get maxConcurrent => _queue.maxConcurrent;

  @override
  int get activeCount => _queue.activeCount;

  @override
  int get queuedCount => _queue.queuedCount;

  @override
  ImageDownloadTicket acquire() {
    acquired++;
    return _queue.acquire();
  }

  @override
  void release(ImageDownloadTicket ticket) => _queue.release(ticket);
}

void main() {
  late _CountingQueue queue;

  setUp(() {
    queue = _CountingQueue();
    ImageDownloadQueue.instance = queue;
  });

  tearDown(ImageDownloadQueue.resetInstance);

  testWidgets('MxcImage_whenNoActiveClient_loadsOnceWithoutRetrying', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: [activeMatrixClientProvider.overrideWithValue(null)],
        child: MaterialApp(
          home: MxcImage(
            uri: Uri.parse('mxc://localhost/media'),
            width: 40,
            height: 40,
            placeholder: (_) => const SizedBox(key: Key('placeholder')),
          ),
        ),
      ),
    );

    // Act
    await tester.pump();
    await tester.pump();

    // Assert
    expect(queue.acquired, 1);
    expect(queue.activeCount, 0);
    expect(find.byKey(const Key('placeholder')), findsOneWidget);
  });
}
