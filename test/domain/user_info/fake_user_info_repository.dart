import 'dart:async';

import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility_request.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';

class FakeUserInfoRepository implements UserInfoRepository {
  FakeUserInfoRepository({UserInfoVisibility? visibility, this.error})
    : visibility = visibility ?? UserInfoVisibility();

  UserInfoVisibility visibility;
  Object? error;
  Completer<void>? pendingUpdate;
  final List<String> getVisibilityCalls = [];
  final List<(String, UserInfoVisibilityRequest)> updateCalls = [];

  @override
  Future<UserInfo> getUserInfo(String userId) async {
    if (error != null) throw error!;
    return UserInfo(uid: userId);
  }

  @override
  Future<UserInfoVisibility> getUserVisibility(String userId) async {
    getVisibilityCalls.add(userId);
    if (error != null) throw error!;
    return visibility;
  }

  @override
  Future<UserInfoVisibility> updateUserInfoVisibility(
    String userId,
    UserInfoVisibilityRequest request,
  ) async {
    updateCalls.add((userId, request));
    await pendingUpdate?.future;
    if (error != null) throw error!;
    return visibility = UserInfoVisibility(
      matrixId: userId,
      visibility: request.visibility,
      visibleFields: request.visibleFields,
    );
  }
}
