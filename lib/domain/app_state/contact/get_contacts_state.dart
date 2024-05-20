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
  final List<Contact> contacts;

  const GetContactsSuccess({
    required this.contacts,
  });

  @override
  List<Object?> get props => [contacts];
}

class GetContactsIsEmpty extends Failure {
  const GetContactsIsEmpty();

  @override
  List<Object?> get props => [];
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
