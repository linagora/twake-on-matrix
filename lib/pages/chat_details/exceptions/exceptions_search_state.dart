import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class ExceptionsSearchInitialState extends Initial {
  @override
  List<Object?> get props => [];
}

class ExceptionsSearchSuccessState extends Success {
  final List<User> exceptionsMember;
  final String keyword;

  const ExceptionsSearchSuccessState({
    required this.exceptionsMember,
    required this.keyword,
  });

  @override
  List<Object?> get props => [exceptionsMember, keyword];
}

class ExceptionsSearchEmptyState extends Failure {
  final String keyword;

  const ExceptionsSearchEmptyState({required this.keyword});

  @override
  List<Object?> get props => [keyword];
}
