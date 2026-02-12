import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class RemovedSearchInitialState extends Initial {
  @override
  List<Object?> get props => [];
}

class RemovedSearchSuccessState extends Success {
  final List<User> removedMember;
  final String keyword;

  const RemovedSearchSuccessState({
    required this.removedMember,
    required this.keyword,
  });

  @override
  List<Object?> get props => [removedMember, keyword];
}

class RemovedSearchEmptyState extends Failure {
  final String keyword;

  const RemovedSearchEmptyState({required this.keyword});

  @override
  List<Object?> get props => [keyword];
}
