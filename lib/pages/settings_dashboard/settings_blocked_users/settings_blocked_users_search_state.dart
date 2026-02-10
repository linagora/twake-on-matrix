import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class BlockedUsersSearchInitialState extends Initial {
  @override
  List<Object?> get props => [];
}

class BlockedUsersSearchSuccessState extends Success {
  final List<Profile> blockedUsers;
  final String keyword;

  const BlockedUsersSearchSuccessState({
    required this.blockedUsers,
    required this.keyword,
  });

  @override
  List<Object?> get props => [blockedUsers, keyword];
}

class BlockedUsersSearchEmptyState extends Failure {
  final String keyword;

  const BlockedUsersSearchEmptyState({required this.keyword});

  @override
  List<Object?> get props => [keyword];
}
