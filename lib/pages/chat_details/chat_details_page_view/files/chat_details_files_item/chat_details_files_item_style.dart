import 'package:fluffychat/widgets/file_widget/file_tile_widget_style.dart';
import 'package:flutter/material.dart';

class ChatDetailsFileTileStyle extends FileTileWidgetStyle {
  static const double textTopMargin = 4.0;

  @override
  Color get backgroundColor => Colors.transparent;

  @override
  BorderRadiusGeometry get borderRadius => BorderRadius.circular(8);

  static const double dividerHeight = 1;

  static Color dividerColor(BuildContext context) =>
      Theme.of(context).dividerColor;
}
