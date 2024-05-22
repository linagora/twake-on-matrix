import 'dart:async';

import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:go_router/go_router.dart';
import 'package:keyboard_shortcuts/keyboard_shortcuts.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/pages/chat/cupertino_widgets_bottom_sheet.dart';
import 'package:fluffychat/pages/chat/edit_widgets_dialog.dart';
import 'package:fluffychat/pages/chat/widgets_bottom_sheet.dart';
import 'package:fluffychat/utils/adaptive_bottom_sheet.dart';
import 'matrix.dart';

class ChatSettingsPopupMenu extends StatefulWidget {
  final Room room;
  final bool displayChatDetails;

  const ChatSettingsPopupMenu(this.room, this.displayChatDetails, {super.key});

  @override
  ChatSettingsPopupMenuState createState() => ChatSettingsPopupMenuState();
}

class ChatSettingsPopupMenuState extends State<ChatSettingsPopupMenu> {
  StreamSubscription? notificationChangeSub;

  @override
  void dispose() {
    notificationChangeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    notificationChangeSub ??= Matrix.of(context)
        .client
        .onAccountData
        .stream
        .where((u) => u.type == 'm.push_rules')
        .listen(
          (u) => setState(() {}),
        );
    final items = <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: 'widgets',
        child: Row(
          children: [
            const Icon(Icons.widgets_outlined),
            const SizedBox(width: 12),
            Text(L10n.of(context)!.matrixWidgets),
          ],
        ),
      ),
      widget.room.pushRuleState == PushRuleState.notify
          ? PopupMenuItem<String>(
              value: 'mute',
              child: Row(
                children: [
                  const Icon(Icons.notifications_off_outlined),
                  const SizedBox(width: 12),
                  Text(L10n.of(context)!.muteChat),
                ],
              ),
            )
          : PopupMenuItem<String>(
              value: 'unmute',
              child: Row(
                children: [
                  const Icon(Icons.notifications_on_outlined),
                  const SizedBox(width: 12),
                  Text(L10n.of(context)!.unmuteChat),
                ],
              ),
            ),
      PopupMenuItem<String>(
        value: 'leave',
        child: Row(
          children: [
            const Icon(Icons.delete_outlined),
            const SizedBox(width: 12),
            Text(L10n.of(context)!.leave),
          ],
        ),
      ),
    ];
    if (widget.displayChatDetails) {
      items.insert(
        0,
        PopupMenuItem<String>(
          value: 'details',
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded),
              const SizedBox(width: 12),
              Text(L10n.of(context)!.chatDetails),
            ],
          ),
        ),
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        KeyBoardShortcuts(
          keysToPress: {
            LogicalKeyboardKey.controlLeft,
            LogicalKeyboardKey.keyI,
          },
          helpLabel: L10n.of(context)!.chatDetails,
          onKeysPressed: _showChatDetails,
          child: Container(),
        ),
        KeyBoardShortcuts(
          keysToPress: {
            LogicalKeyboardKey.controlLeft,
            LogicalKeyboardKey.keyW,
          },
          helpLabel: L10n.of(context)!.matrixWidgets,
          onKeysPressed: _showWidgets,
          child: Container(),
        ),
        PopupMenuButton(
          onSelected: (String choice) async {
            switch (choice) {
              case 'widgets':
                if (widget.room.widgets.isNotEmpty) {
                  _showWidgets();
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => EditWidgetsDialog(room: widget.room),
                    useRootNavigator: false,
                  );
                }
                break;
              case 'leave':
                final confirmed = await showOkCancelAlertDialog(
                  useRootNavigator: false,
                  context: context,
                  title: L10n.of(context)!.areYouSure,
                  okLabel: L10n.of(context)!.ok,
                  cancelLabel: L10n.of(context)!.cancel,
                );
                if (confirmed == OkCancelResult.ok) {
                  final success =
                      await TwakeDialog.showFutureLoadingDialogFullScreen(
                    future: () => widget.room.leave(),
                  );
                  if (success.error == null) {
                    context.go('/rooms');
                  }
                }
                break;
              case 'mute':
                await TwakeDialog.showFutureLoadingDialogFullScreen(
                  future: () => widget.room.mute(),
                );
                break;
              case 'unmute':
                await TwakeDialog.showFutureLoadingDialogFullScreen(
                  future: () => widget.room.unmute(),
                );
                break;
              case 'details':
                _showChatDetails();
                break;
            }
          },
          itemBuilder: (BuildContext context) => items,
        ),
      ],
    );
  }

  void _showWidgets() => [TargetPlatform.iOS, TargetPlatform.macOS]
          .contains(Theme.of(context).platform)
      ? showCupertinoModalPopup(
          context: context,
          builder: (context) => CupertinoWidgetsBottomSheet(room: widget.room),
        )
      : showAdaptiveBottomSheet(
          context: context,
          builder: (context) => WidgetsBottomSheet(room: widget.room),
        );

  void _showChatDetails() {
    if (GoRouterState.of(context).path?.endsWith('/details') == true) {
      context.go('/rooms/${widget.room.id}');
    } else {
      context.go('/rooms/${widget.room.id}/details');
    }
  }
}
