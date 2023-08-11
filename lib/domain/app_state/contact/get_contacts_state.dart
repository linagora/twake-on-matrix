import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/lazy_load_success.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';

class GetContactsInitial extends Initial {
  const GetContactsInitial() : super();

  @override
  List<Object?> get props => [];
}

class GetContactsLoading extends Success {
  const GetContactsLoading() : super();

  @override
  List<Object?> get props => [];
}

class GetContactsSuccess extends LazyLoadSuccess<Contact> {
  final String keyword;

  const GetContactsSuccess({
    required super.data,
    required super.offset,
    required super.isEnd,
    required this.keyword,
  });

  @override
  List<Object?> get props => [data, offset, isEnd, keyword];
}

class GetContactsFailed extends Failure {
  final dynamic exception;

  const GetContactsFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}
