import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/exception/spaces/folder_exception.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/domain/spaces/room_list_filter.dart';
import 'package:twake_chat/domain/spaces/usecases/save_folders_usecase.provider.dart';
import 'package:twake_chat/domain/spaces/usecases/watch_folders_usecase.provider.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';
import 'package:twake_chat/providers/room_list/room_list_entries_provider.dart';
import 'package:twake_chat/providers/room_list/room_list_filter_controller.dart';

part 'folders_controller.freezed.dart';
part 'folders_controller.g.dart';

@riverpod
Stream<List<Folder>> savedFolders(Ref ref) =>
    ref.watch(watchFoldersUseCaseProvider).execute();

@freezed
abstract class FoldersState with _$FoldersState {
  const factory FoldersState({
    /// Everything saved, hidden built-ins included.
    @Default(<Folder>[]) List<Folder> saved,

    /// The account data was read: an edit screen may look a folder up.
    @Default(false) bool isLoaded,

    /// Names a save takes off the rooms: the tags stay on the entries until
    /// the sync echoes, and must not bring the folders back meanwhile.
    @Default(<String>{}) Set<String> leavingTags,
  }) = _FoldersState;
}

/// The folders of the user. A save shows at once, then the sync confirms it:
/// the next save starts from what the user sees.
@riverpod
class FoldersController extends _$FoldersController {
  @override
  FoldersState build() {
    ref.watch(activeUserIdProvider);
    // A notifier outlives its rebuilds: a save running now is another account's.
    _generation++;
    _inFlight = 0;
    _confirmed = const [];
    ref.listen(savedFoldersProvider, (_, next) {
      final saved = next.value;
      if (saved == null) return;
      _confirmed = saved;
      // An echo must not undo a save still on its way.
      state = state.copyWith(
        saved: _inFlight == 0 ? saved : state.saved,
        isLoaded: true,
      );
    });
    // Once no entry holds a tag any more, the name is free again.
    ref.listen(roomListEntriesProvider, (_, entries) {
      final held = entries.expand((entry) => entry.folders).toSet();
      final leaving = state.leavingTags.intersection(held);
      if (leaving.length != state.leavingTags.length) {
        state = state.copyWith(leavingTags: leaving);
      }
    });
    return const FoldersState();
  }

  /// Not `roomListFoldersProvider`: it depends on this controller.
  List<Folder> get _shown => listFolders(
    state.saved,
    ref
        .read(roomListEntriesProvider)
        .expand((entry) => entry.folders)
        .toSet()
        .difference(state.leavingTags),
  );

  /// One save at a time, so two drags reach the server in their order.
  Future<void> _pendingSave = Future.value();

  /// What the server holds, to go back to when the last save fails.
  List<Folder> _confirmed = const [];
  int _inFlight = 0;
  int _generation = 0;

  /// Throws a [FolderSaveFailedException]; what the user sees goes back.
  Future<void> _save(
    List<Folder> shown, {
    List<FolderTagChange> changes = const [],
  }) {
    final saved = withHiddenBuiltins(shown);
    final leaving = {
      for (final change in changes)
        if (!change.isIn) change.folderName,
    }.difference(saved.whereType<UserFolder>().map((f) => f.name).toSet());
    state = state.copyWith(
      saved: saved,
      leavingTags: {...state.leavingTags, ...leaving},
    );
    final useCase = ref.read(saveFoldersUseCaseProvider);
    final generation = _generation;
    _inFlight++;
    final save = _pendingSave.catchError((_) {}).then((_) async {
      try {
        await useCase.execute(saved, changes: changes);
        if (generation == _generation) _confirmed = saved;
      } on FolderException {
        if (generation == _generation && ref.mounted) {
          state = state.copyWith(
            saved: _inFlight == 1 ? _confirmed : state.saved,
            leavingTags: state.leavingTags.difference(leaving),
          );
        }
        rethrow;
      } finally {
        if (generation == _generation) _inFlight--;
      }
    });
    _pendingSave = save;
    return save;
  }

  Future<void> reorder(int from, int to) {
    final shown = [..._shown];
    shown.insert(to, shown.removeAt(from));
    return _save(shown);
  }

  /// Brings a hidden built-in back, last.
  Future<void> addBuiltin(BuiltinFolder kind) =>
      _save([..._shown, Folder.builtin(kind)]);

  /// Takes its tag off its rooms (they stay) and drops it from the list; a
  /// built-in is hidden, it can be added back.
  Future<void> remove(Folder removed) {
    final shown = _shown;
    return _save(
      shown.where((folder) => !_isSame(folder, removed)).toList(),
      changes: switch (removed) {
        BuiltinFolderEntry() => const [],
        UserFolder(:final name) => [
          for (final entry in ref.read(roomListEntriesProvider))
            if (entry.folders.contains(name))
              FolderTagChange(roomId: entry.id, folderName: name, isIn: false),
        ],
      },
    );
  }

  /// Throws a [FolderException].
  Future<void> saveBuiltin({
    required BuiltinFolderEntry edited,
    required Set<String> reservedNames,
  }) async {
    final shown = _shown;
    final previous = shown.whereType<BuiltinFolderEntry>().firstWhereOrNull(
      (folder) => folder.kind == edited.kind,
    );
    _checkName(edited.name, previous, shown, reservedNames);
    await _save([
      for (final folder in shown)
        folder is BuiltinFolderEntry && folder.kind == edited.kind
            ? edited
            : folder,
    ]);
  }

  /// Saves a new folder or [previous] edited, [chats] following [picked]. A
  /// chat not among [chats] arrived later: the folder stays free to take it.
  ///
  /// Throws a [FolderException].
  Future<void> saveUserFolder({
    required UserFolder edited,
    required UserFolder? previous,
    required Set<String> picked,
    required List<RoomListEntry> chats,
    required Set<String> reservedNames,
  }) async {
    final name = edited.name.trim();
    if (name.isEmpty) throw const FolderNameRequiredException();
    final shown = _shown;
    _checkName(name, previous, shown, reservedNames);
    final plan = planFolderEdit(
      folder: edited.copyWith(name: name),
      previous: previous,
      picked: picked,
      chats: chats,
    );
    final views = ref.read(roomListFilterControllerProvider.notifier);
    final isSelected =
        previous != null &&
        ref.read(roomListFilterControllerProvider) ==
            RoomListFilter.folder(previous.name);
    await _save(
      previous == null
          ? [...shown, plan.folder]
          : [
              for (final folder in shown)
                if (_isSame(folder, previous))
                  plan.folder
                else if (!_isSame(folder, plan.folder))
                  folder,
            ],
      changes: plan.changes,
    );
    if (isSelected && ref.mounted) views.select(RoomListFilter.of(plan.folder));
  }

  /// Another client may have changed a folder since it was read: a folder is
  /// known by what names it, not by what it holds.
  bool _isSame(Folder folder, Folder other) =>
      RoomListFilter.of(folder) == RoomListFilter.of(other);

  /// A new name two folders would share, or that other clients read as a
  /// built-in. A name already there stays: it is not the user's doing now.
  void _checkName(
    String name,
    Folder? previous,
    List<Folder> shown,
    Set<String> reservedNames,
  ) {
    final lower = name.toLowerCase();
    if (name.isEmpty || lower == previous?.name.toLowerCase()) return;
    // A folder renamed to a name only the tags know: a failed rename left it.
    final isRetry =
        previous is UserFolder &&
        !state.saved.any((folder) => folder.name == name);
    final taken = {
      ...BuiltinFolder.values.map((kind) => kind.name),
      ...reservedNames.map((reserved) => reserved.toLowerCase()),
      for (final folder in shown)
        if (!isRetry || folder.name != name) folder.name.toLowerCase(),
    };
    if (taken.contains(lower)) throw const FolderNameTakenException();
  }
}

/// Folders names are joined to compare them, and no tag holds this.
const String _tagSeparator = '\u0000';

/// The chips after « All », in their order.
@riverpod
List<Folder> roomListFolders(Ref ref) {
  final saved = ref.watch(
    foldersControllerProvider.select((state) => state.saved),
  );
  final leaving = ref.watch(
    foldersControllerProvider.select((state) => state.leavingTags),
  );
  final taggedNames = ref.watch(
    roomListEntriesProvider.select(
      (entries) =>
          (entries
                  .expand((entry) => entry.folders)
                  .toSet()
                  .difference(leaving)
                  .toList()
                ..sort())
              .join(_tagSeparator),
    ),
  );
  return listFolders(
    saved,
    taggedNames.isEmpty ? const [] : taggedNames.split(_tagSeparator),
  );
}
