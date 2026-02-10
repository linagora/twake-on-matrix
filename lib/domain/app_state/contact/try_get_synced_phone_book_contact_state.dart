import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';

class GetSyncedPhoneBookContactSuccessState extends Success {
  final List<Contact> contacts;
  final bool timeAvailableForSyncVault;

  const GetSyncedPhoneBookContactSuccessState({
    required this.contacts,
    required this.timeAvailableForSyncVault,
  });

  @override
  List<Object> get props => [contacts, timeAvailableForSyncVault];
}

class GetSyncedPhoneBookContactIsEmpty extends Failure {
  const GetSyncedPhoneBookContactIsEmpty();

  @override
  List<Object> get props => [];
}

class GetSyncedPhoneBookContactFailure extends Failure {
  final dynamic exception;

  const GetSyncedPhoneBookContactFailure({required this.exception});

  @override
  List<Object> get props => [exception];
}

class HasErrorFromHiveState extends Failure {
  final dynamic exception;

  const HasErrorFromHiveState({required this.exception});

  @override
  List<Object> get props => [exception];
}

class HasErrorFromVaultState extends Failure {
  final dynamic exception;

  const HasErrorFromVaultState({required this.exception});

  @override
  List<Object> get props => [exception];
}

class HasErrorFromChunkState extends Failure {
  final dynamic exception;

  const HasErrorFromChunkState({required this.exception});

  @override
  List<Object> get props => [exception];
}
