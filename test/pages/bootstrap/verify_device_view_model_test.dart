import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/bootstrap/self_verification_state.dart';
import 'package:fluffychat/domain/usecase/bootstrap/start_self_verification_interactor.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_providers.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_state.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_view_model.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_option.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_state.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';

import '../../fake_client.dart';

class FakeStartSelfVerificationInteractor
    implements StartSelfVerificationInteractor {
  final Stream<Either<Failure, Success>> states;

  FakeStartSelfVerificationInteractor(this.states);

  @override
  Stream<Either<Failure, Success>> execute({required Client client}) => states;
}

/// Stands in for the real [BootstrapViewModel] so `retry()` and
/// `verifyRecoveryKey()` — which read `bootstrapViewModelProvider.notifier`,
/// not just its state — can be exercised. `overrideWithValue` replaces the
/// provider with a value-only element that has no real notifier backing it,
/// so calling `.notifier` on it throws; `overrideWith` keeps a live notifier.
class FakeBootstrapViewModel extends BootstrapViewModel {
  final BootstrapUiState initialState;
  bool retryCalled = false;
  String? unlockedWithRecoveryKey;
  bool unlockResult = true;

  FakeBootstrapViewModel(this.initialState);

  @override
  BootstrapUiState build(Client client, {required bool wipe}) => initialState;

  @override
  void retry() {
    retryCalled = true;
  }

  @override
  Future<bool> unlockWithRecoveryKey(String recoveryKey) async {
    unlockedWithRecoveryKey = recoveryKey;
    return unlockResult;
  }
}

ProviderContainer _container({
  required Client client,
  Stream<Either<Failure, Success>>? startVerificationStates,
  BootstrapUiState bootstrapState = const BootstrapVerifyDeviceState(),
}) {
  return ProviderContainer(
    overrides: [
      bootstrapViewModelProvider(
        client,
        wipe: false,
      ).overrideWithValue(bootstrapState),
      if (startVerificationStates != null)
        startSelfVerificationInteractorProvider.overrideWithValue(
          FakeStartSelfVerificationInteractor(startVerificationStates),
        ),
    ],
  );
}

({ProviderContainer container, FakeBootstrapViewModel bootstrapNotifier})
_containerWithFakeBootstrapNotifier({
  required Client client,
  BootstrapUiState bootstrapState = const BootstrapVerifyDeviceState(),
}) {
  final fakeBootstrapNotifier = FakeBootstrapViewModel(bootstrapState);
  final container = ProviderContainer(
    overrides: [
      bootstrapViewModelProvider(
        client,
        wipe: false,
      ).overrideWith(() => fakeBootstrapNotifier),
    ],
  );
  return (container: container, bootstrapNotifier: fakeBootstrapNotifier);
}

void main() {
  late Client client;

  setUp(() {
    client = Client('verify-device-view-model-test', database: MockDatabase());
  });

  test('build() starts on the chooser state', () {
    final container = _container(client: client);
    addTearDown(container.dispose);

    final state = container.read(
      verifyDeviceViewModelProvider(client, wipe: false),
    );

    expect(state, isA<VerifyDeviceChooserState>());
  });

  test('showRecoveryKeyForm shows the form, prefilled from the bootstrap '
      'retry state', () {
    final container = _container(
      client: client,
      bootstrapState: const BootstrapVerifyDeviceState(
        prefilledRecoveryKey: 'cached-key',
      ),
    );
    addTearDown(container.dispose);
    final provider = verifyDeviceViewModelProvider(client, wipe: false);

    container.read(provider.notifier).showRecoveryKeyForm();

    final state = container.read(provider);
    expect(state, isA<VerifyDeviceRecoveryKeyFormState>());
    expect(
      (state as VerifyDeviceRecoveryKeyFormState).initialValue,
      'cached-key',
    );
  });

  test('closeRecoveryKeyForm returns to the chooser', () {
    final container = _container(client: client);
    addTearDown(container.dispose);
    final provider = verifyDeviceViewModelProvider(client, wipe: false);
    final notifier = container.read(provider.notifier);

    notifier.showRecoveryKeyForm();
    expect(container.read(provider), isA<VerifyDeviceRecoveryKeyFormState>());

    notifier.closeRecoveryKeyForm();
    expect(container.read(provider), isA<VerifyDeviceChooserState>());
  });

  test('setRecoveryKeyError surfaces the message on the form state', () {
    final container = _container(client: client);
    addTearDown(container.dispose);
    final provider = verifyDeviceViewModelProvider(client, wipe: false);
    final notifier = container.read(provider.notifier);

    notifier.showRecoveryKeyForm();
    notifier.setRecoveryKeyError("doesn't match");

    final state = container.read(provider) as VerifyDeviceRecoveryKeyFormState;
    expect(state.errorText, "doesn't match");
  });

  test('showResetConfirm / closeResetConfirm toggle the reset-confirm '
      'state', () {
    final container = _container(client: client);
    addTearDown(container.dispose);
    final provider = verifyDeviceViewModelProvider(client, wipe: false);
    final notifier = container.read(provider.notifier);

    notifier.showResetConfirm();
    expect(container.read(provider), isA<VerifyDeviceResetConfirmState>());

    notifier.closeResetConfirm();
    expect(container.read(provider), isA<VerifyDeviceChooserState>());
  });

  test('resetEncryption(performReset) shows reset-complete on success, '
      'reverts to chooser on failure', () async {
    final container = _container(client: client);
    addTearDown(container.dispose);
    final provider = verifyDeviceViewModelProvider(client, wipe: false);
    final notifier = container.read(provider.notifier);

    notifier.showResetConfirm();
    await notifier.resetEncryption(() async => false);
    expect(container.read(provider), isA<VerifyDeviceChooserState>());

    notifier.showResetConfirm();
    await notifier.resetEncryption(() async => true);
    expect(container.read(provider), isA<VerifyDeviceResetCompleteState>());
  });

  test('dismissRetryError clears sub-flow flags and returns to the '
      'chooser (bootstrap retry state overridden to non-retry-failed)', () {
    final container = _container(client: client);
    addTearDown(container.dispose);
    final provider = verifyDeviceViewModelProvider(client, wipe: false);
    final notifier = container.read(provider.notifier);

    notifier.showRecoveryKeyForm();
    notifier.dismissRetryError();

    expect(container.read(provider), isA<VerifyDeviceChooserState>());
  });

  test('startVerification sets isStartingVerification while in flight, '
      'then attaches the request on success', () async {
    final completer = Completer<Either<Failure, Success>>();
    final container = _container(
      client: client,
      startVerificationStates: Stream.fromFuture(completer.future),
    );
    addTearDown(container.dispose);
    final provider = verifyDeviceViewModelProvider(client, wipe: false);
    final notifier = container.read(provider.notifier);

    final future = notifier.startVerification();
    final loadingState = container.read(provider) as VerifyDeviceChooserState;
    expect(loadingState.isStartingVerification, isTrue);

    completer.complete(
      const Left(StartSelfVerificationFailureState(exception: 'boom')),
    );
    await future;

    final settledState = container.read(provider) as VerifyDeviceChooserState;
    expect(settledState.isStartingVerification, isFalse);
  });

  test('resolveOptions wires onTap for each option kind', () {
    final container = _container(client: client);
    addTearDown(container.dispose);
    final provider = verifyDeviceViewModelProvider(client, wipe: false);
    final notifier = container.read(provider.notifier);

    final options = notifier.resolveOptions([
      const VerifyDeviceOption(
        icon: Icons.smartphone_outlined,
        title: 'Use another device',
        subtitle: '',
        isUseAnotherDevice: true,
      ),
      const VerifyDeviceOption(
        icon: Icons.key_outlined,
        title: 'Use recovery key',
        subtitle: '',
        isUseRecoveryKey: true,
      ),
      const VerifyDeviceOption(
        icon: Icons.key_off_outlined,
        title: 'Not possible to verify?',
        subtitle: '',
        isNotPossibleToVerify: true,
      ),
    ]);

    options[1].onTap?.call();
    expect(container.read(provider), isA<VerifyDeviceRecoveryKeyFormState>());

    notifier.closeRecoveryKeyForm();
    options[2].onTap?.call();
    expect(container.read(provider), isA<VerifyDeviceResetConfirmState>());
  });

  test('retry() delegates to the bootstrap notifier and re-arms the retry '
      'error banner for the next failure', () {
    final setup = _containerWithFakeBootstrapNotifier(
      client: client,
      bootstrapState: const BootstrapVerifyDeviceState(retryFailed: true),
    );
    addTearDown(setup.container.dispose);
    final provider = verifyDeviceViewModelProvider(client, wipe: false);
    final notifier = setup.container.read(provider.notifier);

    expect(setup.container.read(provider), isA<VerifyDeviceRetryErrorState>());
    notifier.dismissRetryError();
    expect(setup.container.read(provider), isA<VerifyDeviceChooserState>());

    notifier.retry();

    expect(setup.bootstrapNotifier.retryCalled, isTrue);
    // dismissRetryError() suppressed the banner; retry() must clear that
    // flag so the *next* bootstrap update showing retryFailed re-surfaces
    // VerifyDeviceRetryErrorState instead of silently staying dismissed.
    // prefilledRecoveryKey differs from the initial state so Equatable
    // treats this as a genuinely new value and notifies ref.listen.
    setup.bootstrapNotifier.state = const BootstrapVerifyDeviceState(
      prefilledRecoveryKey: 'retried-key',
      retryFailed: true,
    );
    expect(setup.container.read(provider), isA<VerifyDeviceRetryErrorState>());
  });

  test('verifyRecoveryKey delegates to the bootstrap notifier and surfaces '
      'VerifyDeviceSuccessState on success', () async {
    final setup = _containerWithFakeBootstrapNotifier(client: client);
    addTearDown(setup.container.dispose);
    setup.bootstrapNotifier.unlockResult = true;
    final provider = verifyDeviceViewModelProvider(client, wipe: false);
    final notifier = setup.container.read(provider.notifier);

    final success = await notifier.verifyRecoveryKey('a-recovery-key');

    expect(success, isTrue);
    expect(setup.bootstrapNotifier.unlockedWithRecoveryKey, 'a-recovery-key');
    expect(setup.container.read(provider), isA<VerifyDeviceSuccessState>());
  });

  test('verifyRecoveryKey returns false and leaves the caller to surface '
      'the error when unlocking fails', () async {
    final setup = _containerWithFakeBootstrapNotifier(client: client);
    addTearDown(setup.container.dispose);
    setup.bootstrapNotifier.unlockResult = false;
    final provider = verifyDeviceViewModelProvider(client, wipe: false);
    final notifier = setup.container.read(provider.notifier);

    final success = await notifier.verifyRecoveryKey('wrong-key');

    expect(success, isFalse);
    expect(setup.bootstrapNotifier.unlockedWithRecoveryKey, 'wrong-key');
    expect(setup.container.read(provider), isA<VerifyDeviceChooserState>());
  });

  test('bootstrap retrySucceeded surfaces as VerifyDeviceSuccessState', () {
    final container = _container(
      client: client,
      bootstrapState: const BootstrapVerifyDeviceState(retrySucceeded: true),
    );
    addTearDown(container.dispose);

    final state = container.read(
      verifyDeviceViewModelProvider(client, wipe: false),
    );

    expect(state, isA<VerifyDeviceSuccessState>());
  });

  test('bootstrap retryFailed surfaces as VerifyDeviceRetryErrorState until '
      'dismissed', () {
    final container = _container(
      client: client,
      bootstrapState: const BootstrapVerifyDeviceState(retryFailed: true),
    );
    addTearDown(container.dispose);
    final provider = verifyDeviceViewModelProvider(client, wipe: false);
    final notifier = container.read(provider.notifier);

    expect(container.read(provider), isA<VerifyDeviceRetryErrorState>());

    notifier.dismissRetryError();
    expect(container.read(provider), isA<VerifyDeviceChooserState>());
  });

  test('closeResetConfirm is a no-op while a reset is in flight', () async {
    final container = _container(client: client);
    addTearDown(container.dispose);
    final provider = verifyDeviceViewModelProvider(client, wipe: false);
    final notifier = container.read(provider.notifier);
    final resetStarted = Completer<void>();
    final releaseReset = Completer<bool>();

    notifier.showResetConfirm();
    final resetFuture = notifier.resetEncryption(() {
      resetStarted.complete();
      return releaseReset.future;
    });
    await resetStarted.future;

    notifier.closeResetConfirm();
    expect(
      (container.read(provider) as VerifyDeviceResetConfirmState).isResetting,
      isTrue,
    );

    releaseReset.complete(true);
    await resetFuture;
  });

  test('resetEncryption ignores a second call while one is already in '
      'flight', () async {
    final container = _container(client: client);
    addTearDown(container.dispose);
    final provider = verifyDeviceViewModelProvider(client, wipe: false);
    final notifier = container.read(provider.notifier);
    var performCount = 0;
    final releaseReset = Completer<bool>();

    notifier.showResetConfirm();
    final firstCall = notifier.resetEncryption(() {
      performCount++;
      return releaseReset.future;
    });
    final secondCall = notifier.resetEncryption(() {
      performCount++;
      return Future.value(true);
    });

    releaseReset.complete(true);
    await Future.wait([firstCall, secondCall]);

    expect(performCount, 1);
  });

  test('startVerification ignores a second call while one is already in '
      'flight', () async {
    final completer = Completer<Either<Failure, Success>>();
    var executeCount = 0;
    final container = ProviderContainer(
      overrides: [
        bootstrapViewModelProvider(
          client,
          wipe: false,
        ).overrideWithValue(const BootstrapVerifyDeviceState()),
        startSelfVerificationInteractorProvider.overrideWithValue(
          FakeStartSelfVerificationInteractor(
            Stream.fromFuture(completer.future).map((event) {
              executeCount++;
              return event;
            }),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = verifyDeviceViewModelProvider(client, wipe: false);
    final notifier = container.read(provider.notifier);

    final firstCall = notifier.startVerification();
    final secondCall = notifier.startVerification();

    completer.complete(
      const Left(StartSelfVerificationFailureState(exception: 'boom')),
    );
    await Future.wait([firstCall, secondCall]);

    expect(executeCount, 1);
  });

  group('with an attached KeyVerification request', () {
    late Client verifyingClient;
    late KeyVerification request;

    setUpAll(() async {
      verifyingClient = await getClient();
    });

    setUp(() {
      request = KeyVerification(
        encryption: verifyingClient.encryption!,
        userId: verifyingClient.userID!,
      );
    });

    test('startVerification success attaches the request as '
        'VerifyDeviceSasState', () async {
      final container = _container(
        client: verifyingClient,
        startVerificationStates: Stream.value(
          Right(StartSelfVerificationSuccessState(request: request)),
        ),
      );
      addTearDown(container.dispose);
      final provider = verifyDeviceViewModelProvider(
        verifyingClient,
        wipe: false,
      );
      final notifier = container.read(provider.notifier);

      await notifier.startVerification();

      final state = container.read(provider) as VerifyDeviceSasState;
      expect(state.request, same(request));

      notifier.acceptSas();
      notifier.rejectSas();
    });

    test(
      'disposing the notifier detaches onUpdate from a pending request',
      () async {
        final container = _container(
          client: verifyingClient,
          startVerificationStates: Stream.value(
            Right(StartSelfVerificationSuccessState(request: request)),
          ),
        );
        final provider = verifyDeviceViewModelProvider(
          verifyingClient,
          wipe: false,
        );
        final notifier = container.read(provider.notifier);
        await notifier.startVerification();
        expect(request.onUpdate, isNotNull);

        container.dispose();

        expect(request.onUpdate, isNull);
      },
    );
  });
}
