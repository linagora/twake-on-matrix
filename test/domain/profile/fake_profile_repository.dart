import 'dart:async';

import 'package:twake_chat/domain/profile/entities/account_profile.dart';
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

  @override
  Future<AccountProfile?> fetchProfile(
    String userId, {
    bool fresh = false,
  }) async {
    profileCalls.add((userId, fresh));
    if (fresh) await pendingFresh?.future;
    if (profileError != null) throw profileError!;
    return fresh ? freshProfile : profile;
  }

  @override
  Future<List<AccountProfile>> fetchAccountProfiles() async {
    if (accountsError != null) throw accountsError!;
    return accounts;
  }
}
