import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';

class GetPhonebookContactsInitial extends Initial {
  const GetPhonebookContactsInitial() : super();

  @override
  List<Object?> get props => [];
}

class GetPhonebookContactsLoading extends Success {
  final int progress;

  const GetPhonebookContactsLoading({required this.progress});

  @override
  List<Object?> get props => [progress];
}

class GetPhonebookContactsSuccess extends Success {
  final List<Contact> contacts;

  const GetPhonebookContactsSuccess({required this.contacts});

  @override
  List<Object?> get props => [contacts];
}

class GetPhonebookContactsIsEmpty extends Failure {
  const GetPhonebookContactsIsEmpty();

  @override
  List<Object?> get props => [];
}

class GetPhonebookContactsFailure extends Failure {
  final dynamic exception;

  const GetPhonebookContactsFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}
