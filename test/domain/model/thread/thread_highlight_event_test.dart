import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_rules.dart';

/// THR-M-04 and THR-M-11: a link or a search result opens a thread reply at
/// `/rooms/R/threads/T?event=E`. go_router gives every route of the stack the
/// full URI, so the room Chat under the thread screen reads that `?event=`
/// too. The reply is not in the main timeline: the room must not reload its
/// timeline around it. Only the thread screen jumps to it.
void main() {
  const roomId = '!room:example.com';
  const rootId = r'$root:example.com';
  const replyId = r'$reply:example.com';

  Uri room({String? event}) =>
      Uri.parse(RoomRoute(roomid: roomId, event: event).location);

  Uri thread({String? event}) => Uri.parse(
    ThreadRoute(roomid: roomId, rootid: rootId, event: event).location,
  );

  test('the room screen jumps to the event of a room link', () {
    expect(
      ThreadRules.highlightEventIdFromUri(
        room(event: r'$message:example.com'),
        isThread: false,
      ),
      r'$message:example.com',
    );
  });

  test('the thread screen jumps to the reply of a thread link', () {
    expect(
      ThreadRules.highlightEventIdFromUri(
        thread(event: replyId),
        isThread: true,
      ),
      replyId,
    );
  });

  test('the room under the thread screen does not jump to the reply of the '
      'thread link', () {
    expect(
      ThreadRules.highlightEventIdFromUri(
        thread(event: replyId),
        isThread: false,
      ),
      isNull,
    );
  });

  test('the room under the thread screen ignores the reply also when the '
      'path is not encoded', () {
    // A link typed or pasted by hand, as the user wrote it.
    expect(
      ThreadRules.highlightEventIdFromUri(
        Uri.parse('/rooms/$roomId/threads/$rootId?event=$replyId'),
        isThread: false,
      ),
      isNull,
    );
  });

  test('no event in the link: neither screen jumps', () {
    expect(
      ThreadRules.highlightEventIdFromUri(room(), isThread: false),
      isNull,
    );
    expect(
      ThreadRules.highlightEventIdFromUri(thread(), isThread: true),
      isNull,
    );
    expect(
      ThreadRules.highlightEventIdFromUri(thread(), isThread: false),
      isNull,
    );
  });
}
