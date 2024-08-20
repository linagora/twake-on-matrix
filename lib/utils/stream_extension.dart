import 'dart:async';

import 'package:matrix/matrix.dart';

extension StreamExtension on Stream {
  /// Returns a new Stream which outputs only `true` for every update of the original
  /// stream, ratelimited by the Duration t
  Stream<bool> rateLimit(Duration t) {
    final controller = StreamController<bool>();
    Timer? timer;
    var gotMessage = false;
    // as we call our inline-defined function recursively we need to make sure that the
    // variable exists prior of creating the function. Silly dart.
    Function? onMessage;
    // callback to determine if we should send out an update
    onMessage = () {
      // do nothing if it is already closed
      if (controller.isClosed) {
        return;
      }
      if (timer == null) {
        // if we don't have a timer yet, send out the update and start a timer
        gotMessage = false;
        controller.add(true);
        timer = Timer(t, () {
          // the timer has ended...delete it and, if we got a message, re-run the
          // method to send out an update!
          timer = null;
          if (gotMessage) {
            onMessage?.call();
          }
        });
      } else {
        // set that we got a message
        gotMessage = true;
      }
    };
    final subscription = listen(
      (_) => onMessage?.call(),
      onDone: () => controller.close(),
      onError: (e, s) => controller.addError(e, s),
    );
    // add proper cleanup to the subscription and the controller, to not memory leak
    controller.onCancel = () {
      subscription.cancel();
      controller.close();
    };
    return controller.stream;
  }

  Stream<SyncUpdate> rateLimitWithSyncUpdate(Duration t) {
    final controller = StreamController<SyncUpdate>();
    Timer? timer;
    SyncUpdate? pendingMessage;

    void processMessage() {
      if (controller.isClosed) return;

      if (timer == null && pendingMessage != null) {
        controller.add(pendingMessage!);
        pendingMessage = null;
        timer = Timer(t, () {
          timer = null;
          if (pendingMessage != null) {
            processMessage();
          }
        });
      }
    }

    final subscription = listen(
      (data) {
        pendingMessage = data;
        processMessage();
      },
      onDone: () => controller.close(),
      onError: (e, s) => controller.addError(e, s),
    );

    controller.onCancel = () {
      subscription.cancel();
      timer?.cancel();
      controller.close();
    };

    return controller.stream;
  }
}
