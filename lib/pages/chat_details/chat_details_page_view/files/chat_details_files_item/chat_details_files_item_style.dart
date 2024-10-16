import 'package:fluffychat/widgets/file_widget/file_tile_widget_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class ChatDetailsFileTileStyle extends FileTileWidgetStyle {
  ChatDetailsFileTileStyle();

  static const double textTopMargin = 4.0;

  @override
  Color backgroundColor(BuildContext context, {bool ownMessage = false}) {
    return Colors.transparent;
  }

  @override
  BorderRadiusGeometry get borderRadius => BorderRadius.circular(8);

  static const double dividerHeight = 1;

  static Color dividerColor(BuildContext context) =>
      Theme.of(context).dividerColor;

  static const EdgeInsets bodyPadding = EdgeInsets.only(right: 8.0);
  static const EdgeInsets bodyPaddingWeb = EdgeInsets.all(8.0);
  static const EdgeInsets bodyChildPadding =
      EdgeInsets.symmetric(vertical: 8.0);
  static const EdgeInsets trailingPadding = EdgeInsets.only(left: 8);

  static TextStyle? downloadedFileTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(
            color: LinagoraSysColors.material().primary,
          );
  static const int downloadedFilenameMaxLines = 3;

  static TextStyle? downloadFileTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          );
  static const int downloadFilenameMaxLines = 1;

  static const double wrapperLeftPadding = 8;

  static TextStyle? downloadSizeFileTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const FileTileWidgetStyle().fileInfoColor,
          );

  static double get tileHeight => 56;

  static double get downloadingTileBottomPlaceholder => 16;
  static double get downloadingTileBottomPlaceholderWeb => 22;

  static double get downloadTileBottomPlaceholderWeb => 24;

  static double get downloadingTileInformationPadding => 2;
}
