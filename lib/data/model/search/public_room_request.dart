import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:matrix/matrix.dart';

part 'public_room_request.g.dart';

@JsonSerializable()
class PublicRoomRequest with EquatableMixin {
  @JsonKey(name: 'filter')
  final PublicRoomQueryFilter? filter;

  @JsonKey(name: 'limit')
  final int? limit;

  PublicRoomRequest({
    this.filter,
    this.limit,
  });

  @override
  List<Object?> get props => [
        filter,
        limit,
      ];

  factory PublicRoomRequest.fromJson(Map<String, dynamic> json) =>
      _$PublicRoomRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PublicRoomRequestToJson(this);
}
