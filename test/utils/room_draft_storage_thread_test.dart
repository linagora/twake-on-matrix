import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/utils/room_draft_storage.dart';

/// THR-M-05: the draft of a thread is separate from the room draft, keyed by
/// `roomId|rootId`, and found again when the thread is reopened.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storage = RoomDraftStorage();
  const roomId = '!room:example.com';
  const rootId = r'$root';

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a thread draft is found again when the thread is reopened', () async {
    await storage.save(roomId, 'thread draft', threadRootId: rootId);

    expect(await storage.read(roomId, threadRootId: rootId), 'thread draft');
  });

  test('a thread draft is stored under the roomId|rootId key', () async {
    await storage.save(roomId, 'thread draft', threadRootId: rootId);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('draft_$roomId|$rootId'), 'thread draft');
  });

  test(
    'the thread draft and the room draft do not overwrite each other',
    () async {
      await storage.save(roomId, 'room draft');
      await storage.save(roomId, 'thread draft', threadRootId: rootId);

      expect(await storage.read(roomId), 'room draft');
      expect(await storage.read(roomId, threadRootId: rootId), 'thread draft');
    },
  );

  test('two threads of the same room keep their own drafts', () async {
    await storage.save(roomId, 'draft A', threadRootId: r'$rootA');
    await storage.save(roomId, 'draft B', threadRootId: r'$rootB');

    expect(await storage.read(roomId, threadRootId: r'$rootA'), 'draft A');
    expect(await storage.read(roomId, threadRootId: r'$rootB'), 'draft B');
  });

  test(
    'sending in the thread clears its draft and keeps the room draft',
    () async {
      await storage.save(roomId, 'room draft');
      await storage.save(roomId, 'thread draft', threadRootId: rootId);

      await storage.remove(roomId, threadRootId: rootId);

      expect(await storage.read(roomId, threadRootId: rootId), isNull);
      expect(await storage.read(roomId), 'room draft');
    },
  );

  test(
    'a thread never opened has no draft, even when the room has one',
    () async {
      await storage.save(roomId, 'room draft');

      expect(await storage.read(roomId, threadRootId: rootId), isNull);
    },
  );
}
