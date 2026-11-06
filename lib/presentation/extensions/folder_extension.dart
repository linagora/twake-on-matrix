import 'package:flutter/widgets.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

extension BuiltinFolderLabels on BuiltinFolder {
  /// Its name while the user gave it none.
  String label(L10n l10n) => switch (this) {
    BuiltinFolder.unread => l10n.roomListUnread,
    BuiltinFolder.broadcasts => l10n.roomListBroadcasts,
    BuiltinFolder.directs => l10n.roomListDirects,
    BuiltinFolder.spaces => l10n.roomListSpaces,
    BuiltinFolder.favourites => l10n.roomListFavourites,
  };

  String rule(L10n l10n) => switch (this) {
    BuiltinFolder.unread => l10n.folderRuleUnread,
    BuiltinFolder.broadcasts => l10n.folderRuleBroadcasts,
    BuiltinFolder.directs => l10n.folderRuleDirects,
    BuiltinFolder.spaces => l10n.folderRuleSpaces,
    BuiltinFolder.favourites => l10n.folderRuleFavourites,
  };
}

extension FolderPresentation on Folder {
  String label(L10n l10n) => switch (this) {
    BuiltinFolderEntry(:final name, :final kind) =>
      name.isNotEmpty ? name : kind.label(l10n),
    UserFolder(:final name) => name,
  };

  Future<void> pushEdit(BuildContext context) => switch (this) {
    BuiltinFolderEntry(:final kind) => BuiltinFolderEditRoute(
      kind: kind,
    ).push<void>(context),
    UserFolder(:final name) => FolderEditRoute(name: name).push<void>(context),
  };
}

/// The names of the filters as the user reads them: no folder may take one.
Set<String> builtinFolderLabels(L10n l10n) => {
  for (final kind in BuiltinFolder.values) kind.label(l10n),
};
