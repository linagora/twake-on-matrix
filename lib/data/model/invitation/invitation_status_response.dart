import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invitation_status_response.g.dart';

@JsonSerializable()
class InvitationStatusResponse with EquatableMixin {
  @JsonKey(name: "invitation")
  final Invitation? invitation;

  InvitationStatusResponse({this.invitation});

  factory InvitationStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$InvitationStatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$InvitationStatusResponseToJson(this);

  @override
  List<Object?> get props => [invitation];
}

@JsonSerializable()
class Invitation with EquatableMixin {
  @JsonKey(name: "id")
  final String id;
  @JsonKey(name: "sender")
  final String? sender;
  @JsonKey(name: "recepient")
  final String? recepient;
  @JsonKey(name: "medium")
  final String? medium;
  @JsonKey(name: "expiration")
  final int? expiration;
  @JsonKey(name: "accessed")
  final bool? accessed;
  @JsonKey(name: "room_id")
  final String? roomId;
  @JsonKey(name: "matrix_id")
  final String? matrixId;

  Invitation({
    required this.id,
    this.sender,
    this.recepient,
    this.medium,
    this.expiration,
    this.accessed,
    this.roomId,
    this.matrixId,
  });

  bool get hasMatrixId {
    return matrixId != null && matrixId!.isNotEmpty;
  }

  bool get expiredTimeToInvite {
    if (medium == null || medium!.isEmpty) {
      return true;
    }
    if (expiration == null) {
      return true;
    }
    final expirationDate = DateTime.fromMillisecondsSinceEpoch(expiration!);
    return expirationDate.isBefore(DateTime.now());
  }

  factory Invitation.fromJson(Map<String, dynamic> json) =>
      _$InvitationFromJson(json);

  Map<String, dynamic> toJson() => _$InvitationToJson(this);

  @override
  List<Object?> get props => [
    id,
    sender,
    recepient,
    medium,
    expiration,
    accessed,
    roomId,
    matrixId,
  ];
}
