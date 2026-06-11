// domain/entities/invitation_link.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part '01_invitation_link.freezed.dart';

@freezed
abstract class InvitationLink with _$InvitationLink {
  const factory InvitationLink({
    required String url,
    required DateTime expiresAt,
    required String roomId,
  }) = _InvitationLink;
}
