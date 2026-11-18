import 'package:flutter/widgets.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/domain/spaces/folders.dart';

class SettingsFoldersStyle {
  static const double backPadding = 8;
  static const double chatAvatarSize = 40;
  static const double emojiPickerHeight = 360;
  static const double checkboxSize = 24;
  static const double swatchSize = 32;
  static const double swatchTapSize = 40;
  static const double swatchRingWidth = 2;
  static const double swatchIconSize = 18;
  static const double tintAlpha = 0.3;

  /// What React caps a folder name at.
  static const int maxNameLength = 60;

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

  static const EdgeInsets rowPadding = EdgeInsets.all(LinagoraSpacing.base * 2);
  static const EdgeInsets checkRowPadding = EdgeInsets.symmetric(
    horizontal: LinagoraSpacing.base * 2,
    vertical: LinagoraSpacing.base * 1.5,
  );
  static const EdgeInsets blockPadding = EdgeInsets.symmetric(
    horizontal: LinagoraSpacing.base * 2,
  );
  static const EdgeInsets introPadding = EdgeInsets.fromLTRB(
    LinagoraSpacing.base * 2,
    LinagoraSpacing.base * 2,
    LinagoraSpacing.base * 2,
    LinagoraSpacing.base,
  );
  static const EdgeInsets helpPadding = EdgeInsets.fromLTRB(
    LinagoraSpacing.base * 2,
    0,
    LinagoraSpacing.base * 2,
    LinagoraSpacing.base,
  );
  static const EdgeInsets nameFieldPadding = EdgeInsets.fromLTRB(
    LinagoraSpacing.base * 2,
    LinagoraSpacing.base * 3,
    LinagoraSpacing.base * 2,
    LinagoraSpacing.base * 2,
  );
  static const EdgeInsets sheetPadding = EdgeInsets.fromLTRB(
    LinagoraSpacing.base * 2,
    0,
    LinagoraSpacing.base * 2,
    LinagoraSpacing.base * 2,
  );
  static TextStyle get helpText => LinagoraTextStyle.material().bodySmall
      .copyWith(color: LinagoraSysColors.material().tertiary);

  static const double sectionGap = LinagoraSpacing.base * 2;
  static const double rowGap = LinagoraSpacing.base * 1.5;
}
