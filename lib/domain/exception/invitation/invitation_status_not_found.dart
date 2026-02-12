class InvitationStatusNotFound implements Exception {
  final String userId;
  final String contactId;

  InvitationStatusNotFound({required this.userId, required this.contactId})
    : super();
}
