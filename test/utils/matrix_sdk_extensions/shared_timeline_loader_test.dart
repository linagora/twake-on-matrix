import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/shared_timeline_loader.dart';

class _FakeTimeline extends Fake implements Timeline {
  int cancelCount = 0;

  @override
  void cancelSubscriptions() => cancelCount++;
}

void main() {
  late _FakeTimeline timeline;
  late Completer<Timeline> pendingLoad;
  late int loadCount;
  late SharedTimelineLoader loader;

  setUp(() {
    timeline = _FakeTimeline();
    pendingLoad = Completer<Timeline>();
    loadCount = 0;
    loader = SharedTimelineLoader(() {
      loadCount++;
      return pendingLoad.future;
    });
  });

  test('concurrent callers share one load and one timeline', () async {
    final first = loader.get();
    final second = loader.get();
    pendingLoad.complete(timeline);

    expect(await first, same(timeline));
    expect(await second, same(timeline));
    expect(loadCount, 1);
  });

  test('dispose cancels a loaded timeline', () async {
    pendingLoad.complete(timeline);
    await loader.get();

    loader.dispose();
    await pumpEventQueue();

    expect(timeline.cancelCount, 1);
  });

  test(
    'dispose during the load cancels the timeline once it arrives',
    () async {
      final load = loader.get();
      loader.dispose();
      expect(timeline.cancelCount, 0);

      pendingLoad.complete(timeline);
      await load;
      await pumpEventQueue();

      expect(timeline.cancelCount, 1);
    },
  );

  test('dispose without any load does nothing', () async {
    loader.dispose();
    await pumpEventQueue();

    expect(loadCount, 0);
  });

  test('a failed load is retried by the next call', () async {
    final failed = loader.get();
    pendingLoad.completeError(Exception('db'));
    await expectLater(failed, throwsException);

    pendingLoad = Completer<Timeline>()..complete(timeline);

    expect(await loader.get(), same(timeline));
    expect(loadCount, 2);
  });

  test(
    'a load that throws synchronously is retried by the next call',
    () async {
      var calls = 0;
      final syncThrowLoader = SharedTimelineLoader(() {
        calls++;
        if (calls == 1) throw StateError('no room');
        return Future.value(timeline);
      });

      await expectLater(syncThrowLoader.get(), throwsStateError);

      expect(await syncThrowLoader.get(), same(timeline));
      expect(calls, 2);
    },
  );
}
