import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/usecase/device_settings/get_devices_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/device_settings/device_settings.dart';
import 'package:twake_chat/pages/device_settings/providers/device_settings_providers.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

class _FakeClient extends Fake implements Client {
  @override
  Future<void> updateUserDeviceKeys({Set<String>? additionalUsers}) async {}
}

/// Never answers: the screen stays on its loading state.
class _PendingGetDevicesInteractor extends GetDevicesInteractor {
  @override
  Stream<Either<Failure, Success>> execute({required Client client}) =>
      const Stream.empty();
}

void main() {
  setUp(() => GetIt.instance.registerSingleton(ResponsiveUtils()));

  tearDown(() => GetIt.instance.reset());

  testWidgets('the client dropped while mounted: nothing is shown', (
    tester,
  ) async {
    Client? active = _FakeClient();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeMatrixClientProvider.overrideWith((ref) => active),
          getDevicesInteractorProvider.overrideWithValue(
            _PendingGetDevicesInteractor(),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const DevicesSettings(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Scaffold), findsOneWidget);

    active = null;
    ProviderScope.containerOf(
      tester.element(find.byType(DevicesSettings)),
    ).invalidate(activeMatrixClientProvider);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Scaffold), findsNothing);
  });
}
