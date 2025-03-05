import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/model/addressbook/address_book.dart';

class GetAddressBookInitial extends Initial {
  const GetAddressBookInitial();

  @override
  List<Object?> get props => [];
}

class GetAddressBookSuccessState extends Success {
  final List<AddressBook> addressBooks;

  const GetAddressBookSuccessState({
    required this.addressBooks,
  });

  @override
  List<Object> get props => [addressBooks];
}

class GetAddressBookIsEmptyState extends Failure {
  const GetAddressBookIsEmptyState();

  @override
  List<Object> get props => [];
}

class GetAddressBookFailureState extends Failure {
  final dynamic exception;

  const GetAddressBookFailureState({
    required this.exception,
  });

  @override
  List<Object> get props => [exception];
}
