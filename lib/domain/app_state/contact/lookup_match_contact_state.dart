import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';

class LookupContactsInitial extends Initial {
  const LookupContactsInitial() : super();

  @override
  List<Object?> get props => [];
}

class LookupContactsLoading extends Success {
  const LookupContactsLoading() : super();

  @override
  List<Object?> get props => [];
}

class LookupMatchContactSuccess extends Success {
  final Contact contact;

  const LookupMatchContactSuccess({
    required this.contact,
  });

  @override
  List<Object?> get props => [contact];
}

class LookupContactsEmpty extends Success {
  const LookupContactsEmpty() : super();

  @override
  List<Object?> get props => [];
}

class LookupContactsFailure extends Failure {
  final String keyword;
  final dynamic exception;

  const LookupContactsFailure({
    required this.keyword,
    required this.exception,
  });

  @override
  List<Object?> get props => [keyword, exception];
}
