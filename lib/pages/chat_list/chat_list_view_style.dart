import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/pages/chat_list/chat_list_header_style.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_pills.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_style.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatListViewStyle {
  static final responsiveUtils = getIt.get<ResponsiveUtils>();

  static const double editIconSize = 18.0;

  static const double _audioPlayerHeight = 40;

  static Size preferredSizeAppBar(
    BuildContext context, {
    required bool isSingleColumn,
    bool? hasAudioEvent,
  }) {
    final double audioPlayer = hasAudioEvent == true ? _audioPlayerHeight : 0;
    if (!isSingleColumn) {
      return Size.fromHeight(120 + RoomListFilterStyle.height + audioPlayer);
    }
    return Size.fromHeight(
      AppConfig.toolbarHeight(context) +
          ChatListHeaderStyle.newChatCapsuleGap +
          ChatListHeaderStyle.searchBarContainerHeight +
          RoomListFilterPills.height +
          audioPlayer,
    );
  }

  // Slidable Ratio of one slidable item
  static const double slidableSizeRatio = 0.23;

  static double slidableExtentRatio(int slidablesLength) {
    return slidableSizeRatio * slidablesLength;
  }

  static const EdgeInsets slidablePadding = EdgeInsets.all(4.0);
  static const double slidableIconTextGap = 4.0;

  static const double slidableIconSize = 24.0;

  static Color? pinSlidableColor(bool isFavourite) {
    return isFavourite
        ? LinagoraRefColors.material().tertiary[40]
        : Colors.tealAccent[700];
  }

  static Color? readSlidableColor(bool isUnread) {
    return isUnread
        ? LinagoraRefColors.material().tertiary[40]
        : Colors.deepPurpleAccent[200];
  }

  static Color? muteSlidableColor(bool isMuted) {
    return isMuted
        ? LinagoraRefColors.material().primary[50]
        : LinagoraRefColors.material().primary[40];
  }

  static double dividerHeight = 1.0;
  static double dividerIndent = 8.0;
  static double dividerThickness = 1.0;
}
