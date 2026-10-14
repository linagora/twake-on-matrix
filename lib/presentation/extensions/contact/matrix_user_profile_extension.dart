import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/contact/datasources/matrix_profile_datasource.dart';

extension MatrixUserProfileToProfile on MatrixUserProfile? {
  /// Legacy SDK `Profile` for the widgets still built around it. A `null`
  /// lookup (unknown user, offline) yields an id-only profile.
  Profile toProfile(String userId) => Profile(
    userId: userId,
    displayName: this?.displayName,
    avatarUrl: this?.avatarUrl == null ? null : Uri.tryParse(this!.avatarUrl!),
  );
}
