import 'dart:async';

import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/entities/avatar_upload.dart';
import 'package:twake_chat/domain/profile/repositories/profile_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.profile, this.accounts = const []});

  AccountProfile? profile;
  AccountProfile? freshProfile;
  List<AccountProfile> accounts;
  Object? profileError;
  Object? accountsError;
  Completer<void>? pendingFresh;
  final List<(String, bool)> profileCalls = [];
  Object? writeError;
  Completer<void>? pendingWrite;
  Uri uploadedUri = Uri.parse('mxc://server/uploaded');

  /// Uploads, avatar and name writes, in call order.
  final List<Object?> writes = [];
  final List<AccountProfile> announced = [];

  @override
  Future<AccountProfile?> fetchProfile(
    String userId, {
    bool fresh = false,
  }) async {
    profileCalls.add((userId, fresh));
    // Read before waiting: the server answers with what it had at the call.
    final answer = fresh ? freshProfile : profile;
    if (fresh) await pendingFresh?.future;
    if (profileError != null) throw profileError!;
    return answer;
  }

  @override
  Future<List<AccountProfile>> fetchAccountProfiles() async {
    if (accountsError != null) throw accountsError!;
    return accounts;
  }

  Future<void> _write(Object? value) async {
    writes.add(value);
    await pendingWrite?.future;
    if (writeError != null) throw writeError!;
  }

  @override
  Future<Uri> uploadAvatar(AvatarUpload avatar) async {
    await _write(avatar);
    return uploadedUri;
  }

  @override
  Future<void> saveOwnAvatar(Uri? avatarUrl) => _write(avatarUrl);

  @override
  Future<void> saveOwnDisplayName(String displayName) => _write(displayName);

  @override
  void announceOwnProfile(AccountProfile profile) => announced.add(profile);
}
