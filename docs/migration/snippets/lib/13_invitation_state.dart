// presentation/states/invitation_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';

import '01_invitation_link.dart';

part '13_invitation_state.freezed.dart';

@freezed
sealed class InvitationState with _$InvitationState {
  const factory InvitationState.initial() = InvitationInitial;

  const factory InvitationState.linkReady({
    required InvitationLink link,
    @Default(false) bool isSending,
  }) = InvitationLinkReady;

  const factory InvitationState.sent({required String targetUserId}) =
      InvitationSent;
}
