import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit.dart';
import 'package:fluffychat/pages/chat_details/chat_details_view_style.dart';
import 'package:fluffychat/presentation/enum/chat/chat_details_screen_enum.dart';
import 'package:fluffychat/presentation/mixins/chat_details_tab_mixin.dart';
import 'package:fluffychat/presentation/mixins/handle_video_download_mixin.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:fluffychat/widgets/mixins/twake_context_menu_mixin.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/pages/chat_details/chat_details_view.dart';
import 'package:fluffychat/widgets/matrix.dart';

enum AliasActions { copy, delete, setCanonical }

class ChatDetails extends StatefulWidget {
  final String roomId;
  final bool isInStack;
  final VoidCallback? closeRightColumn;
  final VoidCallback? onTapSearch;

  const ChatDetails({
    super.key,
    required this.roomId,
    required this.isInStack,
    this.closeRightColumn,
    this.onTapSearch,
  });

  @override
  ChatDetailsController createState() => ChatDetailsController();
}

class ChatDetailsController extends State<ChatDetails>
    with
        HandleVideoDownloadMixin,
        PlayVideoActionMixin,
        TickerProviderStateMixin,
        ChatDetailsTabMixin<ChatDetails>,
        TwakeContextMenuMixin {
  final actionsMobileAndTabletKey = const Key('ActionsMobileAndTabletKey');

  final actionsWebAndDesktopKey = const Key('ActionsWebAndDesktopKey');

  final muteNotifier = ValueNotifier<PushRuleState>(
    PushRuleState.notify,
  );

  @override
  Room? get room => Matrix.of(context).client.getRoomById(widget.roomId);

  @override
  ChatDetailsScreenEnum get chatType => ChatDetailsScreenEnum.group;

  String get roomId => widget.roomId;

  @override
  void initState() {
    super.initState();
    initValueNotifiers();
  }

  void initValueNotifiers() {
    muteNotifier.value = room?.pushRuleState ?? PushRuleState.notify;
  }

  @override
  void dispose() {
    super.dispose();
    muteNotifier.dispose();
  }

  void onToggleNotification() async {
    try {
      final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
        future: () async {
          if (muteNotifier.value == PushRuleState.notify) {
            await room?.mute();
            muteNotifier.value = PushRuleState.mentionsOnly;
          } else {
            await room?.unmute();
            muteNotifier.value = PushRuleState.notify;
          }
        },
      );
      if (result.error != null) throw result.error;
    } catch (e) {
      Logs().e('ChatDetailsController.onToggleNotification', e);
      TwakeSnackBar.show(
        context,
        L10n.of(context)!.oopsSomethingWentWrong,
      );
    }
  }

  void onTapSearch() => widget.onTapSearch?.call();

  void onTapMessage() => widget.closeRightColumn?.call();

  Future<void> onTapMoreButton(
    BuildContext context,
    TapDownDetails details,
  ) async {
    final l10n = L10n.of(context)!;
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    final sysColors = LinagoraSysColors.material();
    final result = await showTwakeContextMenu(
      context: context,
      listActions: [
        ContextMenuAction(
          name: l10n.report,
          icon: Icons.flag_outlined,
          styleName: textStyle,
        ),
        ContextMenuAction(
          name: l10n.commandHint_leave,
          icon: Icons.logout,
          colorIcon: sysColors.error,
          styleName: textStyle?.copyWith(color: sysColors.error),
        ),
      ],
      offset: details.globalPosition,
    );
    switch (result) {
      case 0:
        await _reportRoom(context);
        break;
      case 1:
        await _leaveRoom(context);
        break;
      default:
        break;
    }
  }

  Future<void> _reportRoom(BuildContext context) async {
    try {
      final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
        future: () async {
          await Matrix.of(context).client.reportRoom(roomId, 'No reason');
        },
      );
      if (result.error != null) throw result.error;
    } catch (e) {
      Logs().e('ChatDetailsController._reportRoom', e);
      TwakeSnackBar.show(
        context,
        L10n.of(context)!.oopsSomethingWentWrong,
      );
    }
  }

  Future<void> _leaveRoom(BuildContext context) async {
    try {
      final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
        future: () async {
          await room?.leave();
        },
      );
      if (result.error != null) throw result.error;

      if (context.mounted) {
        context.go('/rooms');
      }
    } catch (e) {
      Logs().e('ChatDetailsController._leaveRoom', e);
      TwakeSnackBar.show(
        context,
        L10n.of(context)!.oopsSomethingWentWrong,
      );
    }
  }

  void onTapEditButton() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) {
          return ChatDetailsEdit(
            roomId: roomId,
          );
        },
      ),
    );
  }

  void onTapInviteLink(BuildContext context, String inviteLink) async {
    await TwakeClipboard.instance.copyText(inviteLink);
    TwakeSnackBar.show(
      context,
      L10n.of(context)!.copiedToClipboard,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ChatDetailViewStyle.fixedWidth,
      child: ChatDetailsView(this),
    );
  }
}
