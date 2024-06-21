import 'package:fluffychat/domain/model/search/search_model.dart';
import 'package:matrix/matrix.dart';

class RecentChatSearchModel extends SearchModel {
  final String? roomId;

  final RoomSummary? roomSummary;

  const RecentChatSearchModel(
    this.roomId, {
    this.roomSummary,
    super.displayName,
    super.directChatMatrixID,
  });

  @override
  String get id => roomId ?? '';

  @override
  List<Object?> get props =>
      [roomId, displayName, roomSummary, directChatMatrixID];
}
