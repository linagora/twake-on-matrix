// domain/exceptions/invitation_exception.dart

sealed class InvitationException implements Exception {
  const InvitationException(this.message);
  final String message;
}

class InvitationDisabledException extends InvitationException {
  const InvitationDisabledException()
      : super('Invitations are disabled for this room');
}

class InvitationLinkExpiredException extends InvitationException {
  const InvitationLinkExpiredException()
      : super('Invitation link has expired');
}

class InvitationNetworkException extends InvitationException {
  const InvitationNetworkException(Object cause)
      : super('Network error: $cause');
}
