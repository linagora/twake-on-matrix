
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/pages/chat/chat_app_bar_title_style.dart';
import 'package:fluffychat/pages/chat/send_file_dialog.dart';
import 'package:fluffychat/pages/forward/forward.dart';
import 'package:fluffychat/pages/forward/forward_item.dart';
import 'package:fluffychat/pages/forward/forward_view_style.dart';
import 'package:fluffychat/pages/forward/presentation_forward.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:vrouter/vrouter.dart';

class ForwardView extends StatefulWidget {
  final ForwardController controller;
  const ForwardView(this.controller, {super.key});

  @override
  State<ForwardView> createState() => _ForwardViewState();
}

class _ForwardViewState extends State<ForwardView> {
  bool isShowRecentlyChats = false;
  bool isShowContactChats = false;
  bool isSearchBarShow = false;

  void _toggleRecentlyChats() {
    setState(() {
      isShowRecentlyChats = !isShowRecentlyChats;
    });
  }

  void _toggleContactChats() {
    setState(() {
      isShowContactChats = !isShowContactChats;
    });
  }

  void _forwardRecentlyChatAction(List<Room> rooms) async {
    final room = rooms.firstWhere((element) => element.id == widget.controller.selectedEvents.first.id);
    _sendForwardMessageAction(room);
  }

  void _forwardContactsChatAction(List<Room> rooms) async {
    final roomId = await Matrix.of(context).client.startDirectChat(
      widget.controller.selectedEvents.first.id.toTomMatrixId()
    );

    final hasRoom = rooms.any((element) => element.id == roomId);
    if (hasRoom) {
      final room = rooms.firstWhere((element) => element.id == roomId);
      _sendForwardMessageAction(room);
    } else {
      await Matrix.of(context).client.getRoomById(roomId)!.leave();
    }
  }

  void _sendForwardMessageAction(Room room) async {
    if (room.membership == Membership.join) {
      final shareContent = Matrix.of(context).shareContent;
      if (shareContent != null) {
        final shareFile = shareContent.tryGet<MatrixFile>('file');
        if (shareContent.tryGet<String>('msgtype') == 'chat.fluffy.shared_file' && shareFile != null) {
          await showDialog(
          context: context,
          useRootNavigator: false,
          builder: (c) => SendFileDialog(
            files: [shareFile],
            room: room,
          ),
          );
        } else {
          room.sendEvent(shareContent);
        }
        Matrix.of(context).shareContent = null;
      }
      VRouter.of(context).toSegments(['rooms', room.id]);
    }
  }

  void forwardAction(BuildContext context) async {
    final rooms = widget.controller.filteredRoomsForAll;
    switch (widget.controller.selectedEvents.first.type) {
      case ForwardTypeEnum.recently:
        _forwardRecentlyChatAction(rooms);
        break;
      case ForwardTypeEnum.contacts:
        _forwardContactsChatAction(rooms);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ForwardViewStyle.preferredAppBarSize),
        child: _buildAppBarForward(context)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ForwardViewStyle.paddingBody),
        child: Column(
          children: [
            _buildChatHeaderFolders(
              context,
              title: L10n.of(context)!.recentlyChats,
              isSelect: isShowRecentlyChats,
              onPressed: () => _toggleRecentlyChats()
            ),
            if (isShowRecentlyChats)
              _buildBodyRecentlyChatList(),
            _buildBodyContactsChatList(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    if (widget.controller.selectedEvents.length == 1) {
      return SizedBox(
        height: ForwardViewStyle.bottomBarHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: TwakeIconButton(
                  size: ForwardViewStyle.iconSendSize,
                  onPressed: () {
                    forwardAction(context);
                  },
                  tooltip: L10n.of(context)!.send,
                  imagePath: ImagePaths.icSend,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildAppBarForward(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      surfaceTintColor: Colors.transparent,
      leadingWidth: double.infinity,
      leading: Row(
        children: [
          TwakeIconButton(
            tooltip: L10n.of(context)!.back,
            icon: Icons.arrow_back,
            onPressed: () {
              Matrix.of(context).shareContent = null;
              VRouter.of(context).pop();
            },
            paddingAll: 8.0,
            margin: const EdgeInsets.symmetric(vertical: 12.0),
          ),
          const SizedBox(width: 8.0),
          isSearchBarShow
            ? Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextField(
                  autofocus: true,
                  maxLines: 1,
                  buildCounter: (BuildContext context, {
                    required int currentLength,
                    required int? maxLength,
                    required bool isFocused,
                  }) => const SizedBox.shrink(),
                  maxLength: 200,
                  cursorHeight: 26,
                  scrollPadding: const EdgeInsets.all(0),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    hintText: "...",
                    hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: LinagoraRefColors.material().neutral[60]),
                  )))
            : Text(
              L10n.of(context)!.forwardTo,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: ChatAppBarTitleStyle.letterSpacingRoomName)),
        ],
      ),
      actions: [
        TwakeIconButton(
          icon: Icons.search,
          onPressed: () {},
          tooltip: L10n.of(context)!.search,
        ),
      ],
      bottom: PreferredSize(
          preferredSize: const Size(double.infinity, 4),
          child: Container(
              color: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.08),
              height: 1)),
    );
  }

  Widget _buildBodyRecentlyChatList() {
    final rooms = widget.controller.filteredRoomsForAll;
    if (rooms.isEmpty) {
      const SizedBox();
    } else {
      return ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        controller: widget.controller.forwardListController,
        itemCount: rooms.length,
        itemBuilder: (BuildContext context, int i) {

          final displayName = rooms[i].getLocalizedDisplayname(
            MatrixLocals(L10n.of(context)!),
          );

          return ForwardItem(
            id: rooms[i].id,
            key: Key('forward_recently_${rooms[i].id}'),
            displayName: displayName,
            selected: widget.controller.selectedEvents.contains(
              ForwardToSelection(rooms[i].id, ForwardTypeEnum.recently)
            ),
            onTap: () {
              widget.controller.onSelectChat(ForwardToSelection(rooms[i].id, ForwardTypeEnum.recently));
            },
          );
        },
      );
    }
    return const SizedBox();
  }

  Widget _buildChatHeaderFolders(
    BuildContext context,
    {
      required String title,
      bool isSelect = false,
      void Function()? onPressed
    }
  ) {
    return Row(
      children: [
        Text(title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: LinagoraRefColors.material().neutral[40])
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TwakeIconButton(
                paddingAll: 6.0,
                buttonDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                icon: isSelect ? Icons.expand_less : Icons.expand_more,
                onPressed: onPressed,
                tooltip: isSelect
                  ? L10n.of(context)!.shrink
                  : L10n.of(context)!.expand),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildBodyContactsChatList(BuildContext context) {
    return StreamBuilder(
      stream: widget.controller.streamController.stream,
      builder: (context, AsyncSnapshot<Either<Failure, GetContactsSuccess>> snapshot) {

        if (!snapshot.hasData) {
           return const SizedBox();
         }

        if (snapshot.hasError || snapshot.data?.isLeft() != false) {
          return const SizedBox();
        }

         final contactsList = snapshot.data!.fold(
           (failure) => <PresentationContact>[],
           (success) => success.contacts.expand((contact) => contact.toPresentationContacts()),
         ).toSet();

         final contactsListSorted = contactsList.sorted((a, b) => widget.controller.comparePresentationContacts(a, b));

         if (contactsListSorted.isEmpty) {
          return const SizedBox();
        }

         return Column(
           children: [
             const SizedBox(height: 16),
             _buildChatHeaderFolders(
                 context,
                 title: L10n.of(context)!.countTwakeUsers(1),
                 isSelect: isShowContactChats,
                 onPressed: () => _toggleContactChats()
             ),
             if (isShowContactChats)
              for (final contact in contactsListSorted)...[
                ForwardItem(
                  id: contact.matrixId ?? '',
                  key: Key('forward_recently_${contact.matrixId ?? ""}'),
                  displayName: contact.displayName ?? "",
                  selected: widget.controller.selectedEvents.contains(
                    ForwardToSelection(contact.displayName ?? "", ForwardTypeEnum.contacts)),
                  onTap: () {
                    widget.controller.onSelectChat(
                      ForwardToSelection(contact.displayName ?? "", ForwardTypeEnum.contacts));
                  },
                ),
              ]
           ],
         );
      });
  }
}
