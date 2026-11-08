import 'package:flutter/widgets.dart';
import 'package:twake_chat/domain/spaces/folders.dart';

class SettingsFoldersStyle {
  static const double backPadding = 8;
  static const double gap = 16;
  static const double smallGap = 8;
  static const double chipGap = 4;
  static const double chatAvatarSize = 40;
  static const double emojiPickerHeight = 360;
  static const double colorSwatchSize = 16;

  /// What React caps a folder name at.
  static const int maxNameLength = 60;

  /// What shows where a folder has no emoji of its own.
  static const String defaultEmoji = '🙂';
  static const String defaultFolderEmoji = '📁';

  static const List<FolderColor> palette = [
    FolderColor('#E91E63'),
    FolderColor('#9C27B0'),
    FolderColor('#3F51B5'),
    FolderColor('#2196F3'),
    FolderColor('#009688'),
    FolderColor('#4CAF50'),
    FolderColor('#FF9800'),
    FolderColor('#795548'),
  ];

  static const EdgeInsets padding = EdgeInsets.all(gap);
  // Keeps the delete button clear of the drag handle ReorderableListView adds.
  static const EdgeInsetsDirectional trailingPadding =
      EdgeInsetsDirectional.only(end: 24);
}
