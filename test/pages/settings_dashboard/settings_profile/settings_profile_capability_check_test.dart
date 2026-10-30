import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/data/repository/capabilities/server_capabilities_repository.provider.dart';
import 'package:twake_chat/domain/app_state/user_info/get_user_info_state.dart';
import 'package:twake_chat/domain/capabilities/models/profile_edit_capabilities.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/repository/capabilities/server_capabilities_repository.dart';
import 'package:twake_chat/domain/usecase/user_info/get_user_info_interactor.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_capability_check.dart';

class _CountingRepository implements ServerCapabilitiesRepository {
  int calls = 0;

  @override
  Future<ProfileEditCapabilities> fetchProfileEditCapabilities() async {
    calls++;
    return const ProfileEditCapabilities(
      canEditAvatar: false,
      canEditDisplayName: true,
    );
  }
}

class _CountingUserInfoInteractor extends Fake
    implements GetUserInfoInteractor {
  int calls = 0;

  @override
  Stream<Either<Failure, Success>> execute({String? userId}) async* {
    calls++;
    yield Right(GetUserInfoSuccess(UserInfo(uid: userId)));
  }
}

void main() {
  late _CountingUserInfoInteractor userInfoInteractor;

  setUp(() {
    userInfoInteractor = _CountingUserInfoInteractor();
    GetIt.instance.registerSingleton<GetUserInfoInteractor>(userInfoInteractor);
  });

  tearDown(GetIt.instance.reset);

  testWidgets('build_withCapabilitiesAndUserInfo_loadsEachOnce', (
    tester,
  ) async {
    // Arrange
    final repository = _CountingRepository();
    ProfileEditCapabilities? capabilities;
    UserInfo? userInfo;

    // Act
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          serverCapabilitiesRepositoryProvider.overrideWithValue(repository),
        ],
        child: SettingsProfileCapabilityCheck(
          userId: '@me:server',
          builder: (caps, info, _) {
            capabilities = caps;
            userInfo = info;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Assert
    expect(repository.calls, 1);
    expect(userInfoInteractor.calls, 1);
    expect(capabilities?.canEditAvatar, isFalse);
    expect(capabilities?.canEditDisplayName, isTrue);
    expect(userInfo?.uid, '@me:server');
  });
}
