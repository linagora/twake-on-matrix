import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class AssignRolesSearchInitialState extends Initial {
  @override
  List<Object?> get props => [];
}

class AssignRolesSearchSuccessState extends Success {
  final List<User> assignRolesMember;
  final String keyword;

  const AssignRolesSearchSuccessState({
    required this.assignRolesMember,
    required this.keyword,
  });

  @override
  List<Object?> get props => [assignRolesMember, keyword];
}

class AssignRolesSearchEmptyState extends Failure {
  final String keyword;

  const AssignRolesSearchEmptyState({required this.keyword});

  @override
  List<Object?> get props => [keyword];
}
