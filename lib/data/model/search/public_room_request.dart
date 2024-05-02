import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:matrix/matrix.dart';

part 'public_room_request.g.dart';

@JsonSerializable()
class PublicRoomRequest with EquatableMixin {
  @JsonKey(name: 'filter')
  final PublicRoomQueryFilter? filter;

  @JsonKey(name: 'include_all_networks')
  final bool? includeAllNetworks;

  @JsonKey(name: 'limit')
  final int? limit;

  @JsonKey(name: 'since')
  final String? since;

  @JsonKey(name: 'third_party_instance_id')
  final String? thirdPartyInstanceId;

  PublicRoomRequest({
    this.filter,
    this.includeAllNetworks = false,
    this.limit,
    this.since,
    this.thirdPartyInstanceId,
  });

  @override
  List<Object?> get props => [
        filter,
        includeAllNetworks,
        limit,
        since,
        thirdPartyInstanceId,
      ];

  factory PublicRoomRequest.fromJson(Map<String, dynamic> json) =>
      _$PublicRoomRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PublicRoomRequestToJson(this);
}
