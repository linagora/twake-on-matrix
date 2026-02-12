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
  const GetPhonebookContactsLoading();

  @override
  List<Object?> get props => [];
}

class GetPhonebookContactsSuccess extends Success {
  final int progress;
  final List<Contact> contacts;

  const GetPhonebookContactsSuccess({
    required this.progress,
    required this.contacts,
  });

  @override
  List<Object?> get props => [progress, contacts];
}

class GetPhonebookContactsIsEmpty extends Failure {
  const GetPhonebookContactsIsEmpty();

  @override
  List<Object?> get props => [];
}

class GetPhonebookContactsFailure extends Failure {
  final List<Contact> contacts;
  final dynamic exception;

  const GetPhonebookContactsFailure({
    required this.exception,
    required this.contacts,
  });

  @override
  List<Object?> get props => [exception, contacts];
}

class RequestTokenFailure extends Failure {
  final List<Contact> contacts;
  final dynamic exception;

  const RequestTokenFailure({required this.exception, required this.contacts});

  @override
  List<Object?> get props => [exception, contacts];
}

class RegisterTokenFailure extends Failure {
  final List<Contact> contacts;
  final dynamic exception;

  const RegisterTokenFailure({required this.contacts, required this.exception});

  @override
  List<Object?> get props => [exception, contacts];
}

class LookUpPhonebookContactPartialFailed extends Failure {
  final dynamic exception;
  final List<Contact> contacts;

  const LookUpPhonebookContactPartialFailed({
    required this.exception,
    required this.contacts,
  });

  @override
  List<Object?> get props => [exception, contacts];
}

class GetPhoneBookContactFailure extends Failure {
  final dynamic exception;

  const GetPhoneBookContactFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class GetHashDetailsFailure extends Failure {
  final dynamic exception;

  const GetHashDetailsFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class LookUpContactFailure extends Failure {
  final dynamic exception;

  const LookUpContactFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}
