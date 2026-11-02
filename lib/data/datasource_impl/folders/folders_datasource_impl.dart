import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource/folders/folders_datasource.dart';
import 'package:twake_chat/data/datasource_impl/folders/folders_content.dart';
import 'package:twake_chat/data/datasource_impl/spaces/room_list_entry_mapper.dart';
import 'package:twake_chat/domain/exception/spaces/folder_exception.dart';
import 'package:twake_chat/domain/spaces/folders.dart';

class FoldersDatasourceImpl implements FoldersDatasource {
  const FoldersDatasourceImpl(this._client);

  final Client? _client;

  @override
  Stream<List<Folder>> watchFolders() async* {
    final client = _client;
    if (client == null) return;
    // An edit screen reads the rooms of a folder once these have come.
    await client.accountDataLoading;
    await client.roomsLoading;
    yield _saved(client);
    yield* client.onSync.stream
        .where(
          (update) =>
              update.accountData?.any(
                (data) => data.type == foldersAccountDataType,
              ) ??
              false,
        )
        .map((_) => _saved(client));
  }

  List<Folder> _saved(Client client) =>
      readFolders(client.accountData[foldersAccountDataType]?.content);

  @override
  Future<void> saveFolders(
    List<Folder> folders, {
    List<FolderTagChange> changes = const [],
  }) async {
    final client = _client;
    // Before the first sync the folders of the account are unknown: saving
    // would overwrite them with the defaults.
    if (client == null || client.prevBatch == null) {
      throw const FolderSaveFailedException();
    }
    try {
      // Tags first, additions before removals. When a step fails, the list
      // is unchanged but some tags already moved: a chat may be in two
      // folders, a deleted folder stays with chats missing, a renamed one is
      // known by its new tag alone. Saving again repairs it.
      for (final change in changes.where((change) => change.isIn)) {
        await _applyTag(client, change);
      }
      for (final change in changes.where((change) => !change.isIn)) {
        await _applyTag(client, change);
      }
      await client.setAccountData(
        client.userID!,
        foldersAccountDataType,
        writeFolders(folders),
      );
    } on Exception catch (exception, stackTrace) {
      Logs().e('FoldersDatasourceImpl::saveFolders', exception, stackTrace);
      throw const FolderSaveFailedException();
    }
  }

  Future<void> _applyTag(Client client, FolderTagChange change) async {
    final room = client.getRoomById(change.roomId);
    if (room == null) return;
    final tag = '$folderTagPrefix${change.folderName}';
    await (change.isIn ? room.addTag(tag) : room.removeTag(tag));
  }
}
