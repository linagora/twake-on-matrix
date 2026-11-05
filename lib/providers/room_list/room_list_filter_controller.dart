import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/spaces/room_list_filter.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';

part 'room_list_filter_controller.g.dart';

/// The chip the user selected. Kept alive: the header and the list that read
/// it come and go with the layout.
@Riverpod(keepAlive: true)
class RoomListFilterController extends _$RoomListFilterController {
  @override
  RoomListFilter build() {
    // The folders of an account mean nothing to the next one.
    ref.watch(activeUserIdProvider);
    return const RoomListFilter.all();
  }

  void select(RoomListFilter view) => state = view;
}
