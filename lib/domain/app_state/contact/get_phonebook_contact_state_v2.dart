import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/contact/contact_new.dart';

class GetPhonebookContactsV2Initial extends Initial {
  const GetPhonebookContactsV2Initial() : super();

  @override
  List<Object?> get props => [];
}

class GetPhonebookContactsV2Loading extends Success {
  const GetPhonebookContactsV2Loading();

  @override
  List<Object?> get props => [];
}

class GetPhonebookContactsV2Success extends Success {
  final int progress;
  final List<Contact> contacts;

  const GetPhonebookContactsV2Success({
    required this.progress,
    required this.contacts,
  });

  @override
  List<Object?> get props => [
        progress,
        contacts,
      ];
}

class GetPhonebookContactsV2IsEmpty extends Success {
  const GetPhonebookContactsV2IsEmpty();

  @override
  List<Object?> get props => [];
}

class GetPhonebookContactsV2Failure extends Failure {
  final dynamic exception;

  const GetPhonebookContactsV2Failure({
    required this.exception,
  });

  @override
  List<Object?> get props => [exception];
}
