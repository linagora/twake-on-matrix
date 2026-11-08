import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/datasource_impl/folders/folders_content.dart';
import 'package:twake_chat/data/datasource_impl/folders/folders_datasource_impl.dart';
import 'package:twake_chat/domain/exception/spaces/folder_exception.dart';
import 'package:twake_chat/domain/spaces/folders.dart';

import 'folders_datasource_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>(), MockSpec<Room>()])
void main() {
  late MockClient client;
  late FoldersDatasourceImpl datasource;

  setUp(() {
    client = MockClient();
    datasource = FoldersDatasourceImpl(client);
    when(client.userID).thenReturn('@me:own.org');
    when(client.prevBatch).thenReturn('s1');
    when(client.accountData).thenReturn({});
  });

  group('saveFolders', () {
    test('whenSynced_writesTheAccountDataAndTheTags', () async {
      final room = MockRoom();
      when(client.getRoomById('!c')).thenReturn(room);

      await datasource.saveFolders(
        const [Folder.user('Work')],
        changes: const [
          FolderTagChange(roomId: '!c', folderName: 'Work', isIn: true),
          FolderTagChange(roomId: '!c', folderName: 'Old', isIn: false),
          FolderTagChange(roomId: '!gone', folderName: 'Old', isIn: false),
        ],
      );

      verify(room.addTag('u.Work')).called(1);
      verify(room.removeTag('u.Old')).called(1);
      verify(
        client.setAccountData('@me:own.org', foldersAccountDataType, {
          'folders': [
            {'name': 'Work'},
          ],
        }),
      ).called(1);
    });

    test('whenAnotherClientWroteMore_keepsIt', () async {
      when(client.accountData).thenReturn({
        foldersAccountDataType: BasicEvent(
          type: foldersAccountDataType,
          content: {
            'folders': [
              {'builtin': 'future'},
            ],
          },
        ),
      });

      await datasource.saveFolders(const [Folder.user('Work')]);

      verify(
        client.setAccountData('@me:own.org', foldersAccountDataType, {
          'folders': [
            {'name': 'Work'},
            {'builtin': 'future'},
          ],
        }),
      ).called(1);
    });

    test('whenATagFails_doesNotSaveTheFolders', () async {
      final room = MockRoom();
      when(client.getRoomById('!c')).thenReturn(room);
      when(room.addTag('u.Work')).thenThrow(Exception('down'));

      await expectLater(
        datasource.saveFolders(
          const [Folder.user('Work')],
          changes: const [
            FolderTagChange(roomId: '!c', folderName: 'Work', isIn: true),
          ],
        ),
        throwsA(isA<FolderSaveFailedException>()),
      );
      verifyNever(client.setAccountData(any, any, any));
    });

    test('always_addsTagsThenRemovesThemThenSavesTheFolders', () async {
      final room = MockRoom();
      when(client.getRoomById('!c')).thenReturn(room);

      await datasource.saveFolders(
        const [],
        changes: const [
          FolderTagChange(roomId: '!c', folderName: 'Old', isIn: false),
          FolderTagChange(roomId: '!c', folderName: 'New', isIn: true),
        ],
      );

      verifyInOrder([
        room.addTag('u.New'),
        room.removeTag('u.Old'),
        client.setAccountData(any, any, any),
      ]);
    });

    test('whenNotSyncedYet_refusesToOverwriteTheAccount', () async {
      when(client.prevBatch).thenReturn(null);

      await expectLater(
        datasource.saveFolders(const []),
        throwsA(isA<FolderSaveFailedException>()),
      );
      verifyNever(client.setAccountData(any, any, any));
    });

    test('whenServerFails_throwsTyped', () async {
      when(client.setAccountData(any, any, any)).thenThrow(Exception('down'));

      await expectLater(
        datasource.saveFolders(const []),
        throwsA(isA<FolderSaveFailedException>()),
      );
    });
  });

  group('watchFolders', () {
    test('whenNoClient_emitsNothing', () async {
      expect(
        await const FoldersDatasourceImpl(null).watchFolders().isEmpty,
        isTrue,
      );
    });

    test('whenRoomsAreStillLoading_waitsForThem', () async {
      final rooms = Completer<void>();
      when(client.roomsLoading).thenAnswer((_) => rooms.future);
      when(client.onSync).thenReturn(CachedStreamController<SyncUpdate>());
      final emitted = <List<Folder>>[];
      final subscription = datasource.watchFolders().listen(emitted.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      expect(emitted, isEmpty);

      rooms.complete();
      await pumpEventQueue();

      expect(emitted, hasLength(1));
    });

    test('whenAccountDataChanges_emitsAgain', () async {
      final sync = CachedStreamController<SyncUpdate>();
      when(client.onSync).thenReturn(sync);
      when(client.accountData).thenReturn({
        foldersAccountDataType: BasicEvent(
          type: foldersAccountDataType,
          content: {
            'folders': [
              {'name': 'Work'},
            ],
          },
        ),
      });
      final emitted = <List<Folder>>[];
      final subscription = datasource.watchFolders().listen(emitted.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      sync.add(SyncUpdate(nextBatch: 's2'));
      await pumpEventQueue();
      expect(emitted, hasLength(1));

      sync.add(
        SyncUpdate(
          nextBatch: 's3',
          accountData: [
            BasicEvent(type: foldersAccountDataType, content: const {}),
          ],
        ),
      );
      await pumpEventQueue();

      expect(emitted, hasLength(2));
      expect(emitted.last, const [Folder.user('Work')]);
    });
  });
}
