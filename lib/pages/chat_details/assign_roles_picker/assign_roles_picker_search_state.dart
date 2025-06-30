import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class AssignRolesPickerSearchInitialState extends Initial {
  @override
  List<Object?> get props => [];
}

class AssignRolesPickerSearchSuccessState extends Success {
  final List<User> members;
  final String keyword;

  const AssignRolesPickerSearchSuccessState({
    required this.members,
    required this.keyword,
  });

  @override
  List<Object?> get props => [
        members,
        keyword,
      ];
}

class AssignRolesPickerSearchEmptyState extends Failure {
  final String keyword;

  const AssignRolesPickerSearchEmptyState({
    required this.keyword,
  });

  @override
  List<Object?> get props => [keyword];
}
