// domain/entities/invitation_status.dart

import 'package:freezed_annotation/freezed_annotation.dart';

import '01_invitation_link.dart';

part '02_invitation_status.freezed.dart';

enum InvitationMedium { email, sms, link }

@freezed
abstract class InvitationStatus with _$InvitationStatus {
  const factory InvitationStatus({
    required bool isEnabled,
    required InvitationMedium medium,
    InvitationLink? activeLink,
  }) = _InvitationStatus;
}
