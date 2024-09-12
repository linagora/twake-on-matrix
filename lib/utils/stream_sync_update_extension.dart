import 'dart:async';

import 'package:fluffychat/utils/sync_update_extension.dart';
import 'package:matrix/matrix.dart';

extension StreamExtension on Stream<SyncUpdate> {
  Stream<SyncUpdate> rateLimitWithSyncUpdate(Duration t) {
    final controller = StreamController<SyncUpdate>();
    Timer? timer;
    SyncUpdate? pendingMessage;

    void processMessage() {
      if (controller.isClosed) return;

      if (pendingMessage != null && timer == null) {
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
        if (pendingMessage == null) {
          pendingMessage = data;
          processMessage();
          return;
        }
        final mergeData =
            pendingMessage!.combineJoinedRoomUpdateEvents(other: data);
        pendingMessage = mergeData;
        processMessage();
      },
      onDone: () {
        if (pendingMessage != null) {
          controller.add(pendingMessage!);
          pendingMessage = null;
        }
        controller.close();
      },
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
