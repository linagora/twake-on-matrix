import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';

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