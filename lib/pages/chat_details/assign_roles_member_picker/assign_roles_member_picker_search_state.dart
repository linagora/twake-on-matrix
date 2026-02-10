import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class AssignRolesMemberPickerSearchInitialState extends Initial {
  @override
  List<Object?> get props => [];
}

class AssignRolesMemberPickerSearchSuccessState extends Success {
  final List<User> members;
  final String keyword;

  const AssignRolesMemberPickerSearchSuccessState({
    required this.members,
    required this.keyword,
  });

  @override
  List<Object?> get props => [members, keyword];
}

class AssignRolesMemberPickerSearchEmptyState extends Failure {
  final String keyword;

  const AssignRolesMemberPickerSearchEmptyState({required this.keyword});

  @override
  List<Object?> get props => [keyword];
}
