import 'package:equatable/equatable.dart';

class InvitationStatus with EquatableMixin {
  final String invitationId;
  final String contactId;

  InvitationStatus({required this.invitationId, required this.contactId});

  @override
  List<Object?> get props => [invitationId, contactId];
}
