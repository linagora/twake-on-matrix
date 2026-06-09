import 'package:fluffychat/utils/room_draft_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storage = RoomDraftStorage();
  const roomId = '!room:example.com';

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('read returns null when no draft is stored', () async {
    expect(await storage.read(roomId), isNull);
  });

  test('save then read round-trips the draft', () async {
    await storage.save(roomId, 'hello world');
    expect(await storage.read(roomId), 'hello world');
  });

  test('save persists under the draft_<roomId> key', () async {
    await storage.save(roomId, 'draft text');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('draft_$roomId'), 'draft text');
  });

  test('remove deletes the stored draft', () async {
    await storage.save(roomId, 'to be removed');
    await storage.remove(roomId);
    expect(await storage.read(roomId), isNull);
  });

  test('drafts are isolated per room', () async {
    await storage.save(roomId, 'room A draft');
    await storage.save('!other:example.com', 'room B draft');
    expect(await storage.read(roomId), 'room A draft');
    expect(await storage.read('!other:example.com'), 'room B draft');
  });
}
