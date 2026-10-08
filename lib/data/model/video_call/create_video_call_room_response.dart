import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_video_call_room_response.freezed.dart';
part 'create_video_call_room_response.g.dart';

@Freezed(toJson: false)
abstract class CreateVideoCallRoomResponse with _$CreateVideoCallRoomResponse {
  const factory CreateVideoCallRoomResponse({String? url}) =
      _CreateVideoCallRoomResponse;

  factory CreateVideoCallRoomResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateVideoCallRoomResponseFromJson(json);
}
