import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_address.freezed.dart';

/// A room alias or ID, with the servers that can route to it.
@freezed
abstract class RoomAddress with _$RoomAddress {
  const factory RoomAddress(
    String roomIdOrAlias, {
    @Default([]) List<String> via,
  }) = _RoomAddress;
}
