import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/model/addressbook/address_book.dart';

class PostAddressBookInitial extends Initial {
  const PostAddressBookInitial() : super();

  @override
  List<Object?> get props => [];
}

class PostAddressBookLoading extends Success {
  const PostAddressBookLoading();

  @override
  List<Object?> get props => [];
}

class PostAddressBookEmptyState extends Failure {
  const PostAddressBookEmptyState();

  @override
  List<Object?> get props => [];
}

class PostAddressBookResponseIsNullState extends Failure {
  const PostAddressBookResponseIsNullState();

  @override
  List<Object?> get props => [];
}

class PostAddressBookSuccessState extends Success {
  final List<AddressBook> updatedAddressBooks;

  const PostAddressBookSuccessState({required this.updatedAddressBooks});

  @override
  List<Object> get props => [updatedAddressBooks];
}

class PostAddressBookFailureState extends Failure {
  final dynamic exception;

  const PostAddressBookFailureState({required this.exception});

  @override
  List<Object> get props => [exception];
}
