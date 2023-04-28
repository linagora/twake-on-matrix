import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:fluffychat/pages/contacts/domain/state/get_contacts_success.dart';
import 'package:fluffychat/state/failure.dart';

class PresentationContactsInfo extends Equatable {

  final String title;

  final Stream<Either<Failure, GetContactsSuccess>> contactsStream;

  final bool expanded;

  final ContactType contactType;

  const PresentationContactsInfo({
    required this.title,
    required this.contactsStream,
    required this.contactType,
    this.expanded = true,
  });

  @override
  List<Object?> get props => [contactsStream, expanded, contactType, title];
}

enum ContactType {
  device,
  server
}