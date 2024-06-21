import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit.dart';
import 'package:fluffychat/pages/chat_details/chat_details_view_style.dart';
import 'package:fluffychat/presentation/enum/chat/chat_details_screen_enum.dart';
import 'package:fluffychat/presentation/mixins/chat_details_tab_mixin.dart';
import 'package:fluffychat/presentation/mixins/handle_video_download_mixin.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/pages/chat_details/chat_details_view.dart';
import 'package:fluffychat/widgets/matrix.dart';

enum AliasActions { copy, delete, setCanonical }

class ChatDetails extends StatefulWidget {
  final String roomId;
  final bool isInStack;
  final VoidCallback? closeRightColumn;

  const ChatDetails({
    super.key,
    required this.roomId,
    required this.isInStack,
    this.closeRightColumn,
  });

  @override
  ChatDetailsController createState() => ChatDetailsController();
}

class ChatDetailsController extends State<ChatDetails>
    with
        HandleVideoDownloadMixin,
        PlayVideoActionMixin,
        SingleTickerProviderStateMixin,
        ChatDetailsTabMixin<ChatDetails> {
  final actionsMobileAndTabletKey = const Key('ActionsMobileAndTabletKey');

  final actionsWebAndDesktopKey = const Key('ActionsWebAndDesktopKey');

  final muteNotifier = ValueNotifier<PushRuleState>(
    PushRuleState.notify,
  );

  @override
  Room? get room => Matrix.of(context).client.getRoomById(widget.roomId);

  @override
  ChatDetailsScreenEnum get chatType => ChatDetailsScreenEnum.group;

  String? get roomId => widget.roomId;

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
    if (muteNotifier.value == PushRuleState.notify) {
      await room?.mute();
      muteNotifier.value = PushRuleState.mentionsOnly;
    } else {
      await room?.unmute();
      muteNotifier.value = PushRuleState.notify;
    }
  }

  void onTapEditButton() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) {
          return ChatDetailsEdit(
            roomId: roomId!,
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
