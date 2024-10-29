import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:fluffychat/presentation/model/chat_list/chat_selection_actions.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mixins/on_account_data_listen_mixin.dart';
import 'package:fluffychat/widgets/mixins/show_dialog_mixin.dart';
import 'package:fluffychat/widgets/twake_components/twake_header_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class TwakeHeader extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onClearSelection;
  final ValueNotifier<SelectMode> selectModeNotifier;
  final ValueNotifier<List<ConversationSelectionPresentation>>
      conversationSelectionNotifier;
  final VoidCallback onClickAvatar;
  final Client client;

  const TwakeHeader({
    super.key,
    required this.onClearSelection,
    required this.client,
    required this.selectModeNotifier,
    required this.conversationSelectionNotifier,
    required this.onClickAvatar,
  });

  @override
  State<TwakeHeader> createState() => _TwakeHeaderState();

  @override
  Size get preferredSize =>
      const Size.fromHeight(TwakeHeaderStyle.toolbarHeight);
}

class _TwakeHeaderState extends State<TwakeHeader>
    with ShowDialogMixin, OnProfileChangeMixin {
  final ValueNotifier<Profile> currentProfileNotifier = ValueNotifier(
    Profile(userId: ''),
  );

  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  void getCurrentProfile(Client client) async {
    currentProfileNotifier.value = Profile(userId: '');
    final profile = await client.getProfileFromUserId(
      widget.client.userID!,
      getFromRooms: false,
    );
    Logs().d(
      'ChatList::_getCurrentProfile() - currentProfile1: $profile',
    );
    currentProfileNotifier.value = profile;
  }

  @override
  void didUpdateWidget(covariant TwakeHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (Matrix.of(context).isValidActiveClient &&
        widget.client != oldWidget.client) {
      getCurrentProfile(widget.client);
      onAccountDataSubscription?.cancel();
      listenOnProfileChangeStream(
        client: Matrix.of(context).client,
        currentProfile: currentProfileNotifier.value,
        onProfileChanged: (newProfile) {
          currentProfileNotifier.value = newProfile;
        },
      );
    }
    if (currentProfileNotifier.value.userId.isEmpty) {
      getCurrentProfile(widget.client);
    }
  }

  @override
  void dispose() {
    super.dispose();
    currentProfileNotifier.dispose();
    onAccountDataSubscription?.cancel();
  }

  @override
  void initState() {
    super.initState();
    listenOnProfileChangeStream(
      client: Matrix.of(context).client,
      currentProfile: currentProfileNotifier.value,
      onProfileChanged: (newProfile) {
        currentProfileNotifier.value = newProfile;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.selectModeNotifier,
      builder: (context, selectMode, _) {
        return selectMode == SelectMode.normal
            ? TwakeAppBar(
                title: L10n.of(context)!.chats,
                context: context,
              )
            : AppBar(
                backgroundColor: responsive.isMobile(context)
                    ? LinagoraSysColors.material().background
                    : LinagoraSysColors.material().onPrimary,
                toolbarHeight: TwakeHeaderStyle.toolbarHeight,
                automaticallyImplyLeading: false,
                leadingWidth: TwakeHeaderStyle.leadingWidth,
                title: Align(
                  alignment: TwakeHeaderStyle.alignment,
                  child: Row(
                    mainAxisAlignment: responsive.isMobile(context)
                        ? TwakeHeaderStyle.mobileTitleAllignement
                        : MainAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: TwakeHeaderStyle.flexActions,
                        child: Padding(
                          padding: TwakeHeaderStyle.leadingPadding,
                          child: Row(
                            children: [
                              InkWell(
                                onTap: selectMode == SelectMode.select
                                    ? widget.onClearSelection
                                    : null,
                                borderRadius: BorderRadius.circular(
                                  TwakeHeaderStyle.closeIconSize,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: TwakeHeaderStyle.closeIconSize,
                                  color: selectMode == SelectMode.select
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                      : Colors.transparent,
                                ),
                              ),
                              ValueListenableBuilder(
                                valueListenable:
                                    widget.conversationSelectionNotifier,
                                builder: (context, conversationSelection, _) {
                                  return Padding(
                                    padding: TwakeHeaderStyle
                                        .counterSelectionPadding,
                                    child: Text(
                                      conversationSelection.length.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color:
                                                selectMode == SelectMode.select
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant
                                                    : Colors.transparent,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                centerTitle: true,
              );
      },
    );
  }
}
