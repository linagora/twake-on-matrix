import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/data/repository/user_info_repository.provider.dart';
import 'package:twake_chat/domain/app_state/capabilities/get_server_capabilities_state.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/usecase/capabilities/get_server_capabilities_interactor.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_capability_check.dart';

import '../../../domain/user_info/fake_user_info_repository.dart';

class _CountingCapabilitiesInteractor extends Fake
    implements GetServerCapabilitiesInteractor {
  int calls = 0;

  @override
  Stream<Either<Failure, Success>> execute() async* {
    calls++;
    yield Right(GettingServerCapabilities());
    yield Right(GetServerCapabilitiesSuccess(Capabilities()));
  }
}

void main() {
  late _CountingCapabilitiesInteractor interactor;

  setUp(() {
    interactor = _CountingCapabilitiesInteractor();
    GetIt.instance.registerSingleton<GetServerCapabilitiesInteractor>(
      interactor,
    );
  });

  tearDown(GetIt.instance.reset);

  testWidgets('loads the capabilities once while the user info resolves', (
    tester,
  ) async {
    Capabilities? capabilities;
    UserInfo? userInfo;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ProviderContainer.test(
          retry: (_, _) => null,
          overrides: [
            userInfoRepositoryProvider.overrideWithValue(
              FakeUserInfoRepository(),
            ),
          ],
        ),
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

    expect(interactor.calls, 1);
    expect(capabilities, isNotNull);
    expect(userInfo?.uid, '@me:server');
  });
}
