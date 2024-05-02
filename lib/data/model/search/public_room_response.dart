import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:matrix/matrix.dart';

part 'public_room_response.g.dart';

@JsonSerializable()
class PublicRoomResponse with EquatableMixin {
  @JsonKey(name: 'chunk')
  final PublicRoomsChunk chunk;

  @JsonKey(name: 'next_batch')
  final String? nextBatch;

  @JsonKey(name: 'prev_batch')
  final String? prevBatch;

  @JsonKey(name: 'total_room_count_estimate')
  final int? totalRoomCountEstimate;

  PublicRoomResponse({
    required this.chunk,
    this.nextBatch,
    this.prevBatch,
    this.totalRoomCountEstimate,
  });

  @override
  List<Object?> get props => [
        chunk,
        nextBatch,
        prevBatch,
        totalRoomCountEstimate,
      ];

  factory PublicRoomResponse.fromJson(Map<String, dynamic> json) =>
      _$PublicRoomResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PublicRoomResponseToJson(this);
}
