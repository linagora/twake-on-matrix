import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/lazy_load_success.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';

class GetContactsAllInitial extends Initial {
  const GetContactsAllInitial() : super();

  @override
  List<Object?> get props => [];
}

class GetContactsAllLoading extends Success {
  const GetContactsAllLoading() : super();

  @override
  List<Object?> get props => [];
}

class GetContactsAllSuccess extends LazyLoadSuccess<Contact> {
  final String keyword;

  const GetContactsAllSuccess({
    required super.tomContacts,
    super.phonebookContacts,
    required this.keyword,
  });

  @override
  List<Object?> get props => [tomContacts, phonebookContacts, keyword];
}

class GetContactsAllFailure extends Failure {
  final String keyword;
  final dynamic exception;

  const GetContactsAllFailure({
    required this.keyword,
    required this.exception,
  });

  @override
  List<Object?> get props => [keyword, exception];
}
