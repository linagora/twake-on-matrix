import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';

class ContactsInitial extends Initial {
  const ContactsInitial() : super();

  @override
  List<Object?> get props => [];
}

class ContactsLoading extends Success {
  const ContactsLoading() : super();

  @override
  List<Object?> get props => [];
}

class GetContactsSuccess extends Success {
  final String keyword;
  final List<Contact> tomContacts;
  final List<Contact>? phonebookContacts;

  const GetContactsSuccess({
    required this.tomContacts,
    this.phonebookContacts,
    required this.keyword,
  });

  @override
  List<Object?> get props => [tomContacts, phonebookContacts, keyword];
}

class SearchExternalContactsSuccessState extends Success {
  final String keyword;

  const SearchExternalContactsSuccessState({
    required this.keyword,
  });

  @override
  List<Object?> get props => [
        keyword,
      ];
}

class GetContactsFailure extends Failure {
  final String keyword;
  final dynamic exception;

  const GetContactsFailure({
    required this.keyword,
    required this.exception,
  });

  @override
  List<Object?> get props => [keyword, exception];
}
