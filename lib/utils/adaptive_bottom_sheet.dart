import 'package:flutter/material.dart';

import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/utils/platform_infos.dart';

Future<T?> showAdaptiveBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  bool isScrollControlled = false,
  bool showDragHandle = false,
}) => showModalBottomSheet(
  context: context,
  builder: builder,
  showDragHandle: showDragHandle,
  useRootNavigator: !PlatformInfos.isMobile,
  isDismissible: isDismissible,
  isScrollControlled: isScrollControlled,
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height - 128,
    maxWidth: TwakeThemes.columnWidth * 1.5,
  ),
  clipBehavior: Clip.hardEdge,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(AppConfig.borderRadius),
      topRight: Radius.circular(AppConfig.borderRadius),
    ),
  ),
);
