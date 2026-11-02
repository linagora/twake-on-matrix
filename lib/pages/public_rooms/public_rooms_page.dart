import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/empty_state/linagora_empty_state.dart';
import 'package:linagora_design_flutter/list_item/linagora_avatar_list_item.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/generated/assets.gen.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_controller.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_state.dart';
import 'package:twake_chat/pages/search/search_text_field.dart';
import 'package:twake_chat/utils/search/search_engine.dart';
import 'package:twake_chat/utils/search/search_options.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';

class PublicRoomsPage extends ConsumerStatefulWidget {
  const PublicRoomsPage({super.key});

  @override
  ConsumerState<PublicRoomsPage> createState() => _PublicRoomsPageState();
}

class _PublicRoomsPageState extends ConsumerState<PublicRoomsPage> {
  static const _searchOptions = SearchOptions(diacriticSensitive: false);

  // Same insets as the chat list rows and its search field.
  static const _listPadding = EdgeInsets.symmetric(horizontal: 8);
  static const _searchFieldPadding = EdgeInsetsDirectional.only(end: 8);

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _open(PublicRoom room) async {
    final l10n = L10n.of(context)!;
    final result = await ref
        .read(publicRoomsControllerProvider.notifier)
        .open(room);
    if (!mounted) return;
    switch (result) {
      case PublicRoomJoined(:final roomId):
        RoomRoute(roomid: roomId).go(context);
        Navigator.of(context).pop();
      case PublicRoomRequested():
        TwakeSnackBar.show(context, l10n.joinRequestSentAdminMustApprove);
      case PublicRoomOpenFailed():
        TwakeSnackBar.show(context, l10n.publicGroupJoinFailed);
      case PublicRoomOpenIgnored():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final state = ref.watch(publicRoomsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 8,
        title: Padding(
          padding: _searchFieldPadding,
          child: Row(
            children: [
              TwakeIconButton(
                tooltip: l10n.back,
                icon: Icons.arrow_back_ios,
                onTap: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SearchTextField(
                  textEditingController: _searchController,
                  hintText: l10n.searchPublicGroups,
                ),
              ),
            ],
          ),
        ),
        bottom: state.value?.pendingRoomId != null
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: switch (state) {
        AsyncData(:final value) => ValueListenableBuilder(
          valueListenable: _searchController,
          builder: (context, query, _) => _buildList(
            const SearchEngine().matchAnyField(
              query.text.trim(),
              value.rooms,
              fieldExtractors: [
                (room) => [room.name],
              ],
              options: _searchOptions,
            ),
          ),
        ),
        AsyncError() => GestureDetector(
          onTap: () => ref.invalidate(publicRoomsControllerProvider),
          child: _emptyState(l10n.publicGroupsLoadFailed, l10n.tapToRetry),
        ),
        _ => Center(
          child: CircularProgressIndicator(semanticsLabel: l10n.publicGroups),
        ),
      },
    );
  }

  Widget _buildList(List<PublicRoom> rooms) {
    final l10n = L10n.of(context)!;
    if (rooms.isEmpty) return _emptyState(l10n.noPublicGroupToJoin, null);
    return ListView.builder(
      padding: _listPadding,
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        final access = room.access == PublicRoomAccess.approval
            ? l10n.askToJoinPublicGroupMembers(room.memberCount)
            : l10n.joinPublicGroupMembers(room.memberCount);
        final topic = room.topic;
        return LinagoraAvatarListItem(
          key: ValueKey(room.roomId),
          avatar: _PublicRoomAvatar(room),
          title: room.name,
          subtitle: topic == null || topic.isEmpty
              ? access
              : '$access · $topic',
          onTap: () => _open(room),
        );
      },
    );
  }

  Widget _emptyState(String title, String? description) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LinagoraEmptyState(
        compact: true,
        illustration: SvgPicture.asset(Assets.images.icEmptySearch.path),
        title: title,
        description: description,
      ),
    ),
  );
}

class _PublicRoomAvatar extends StatelessWidget {
  const _PublicRoomAvatar(this.room);

  final PublicRoom room;

  @override
  Widget build(BuildContext context) =>
      Avatar(mxContent: room.avatarUri, name: room.name);
}
