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
import 'package:matrix/matrix.dart';

import '../../fake_client.dart' show MockDatabase;

class FakeStartSelfVerificationInteractor
    implements StartSelfVerificationInteractor {
  final Stream<Either<Failure, Success>> states;

  FakeStartSelfVerificationInteractor(this.states);

  @override
  Stream<Either<Failure, Success>> execute({required Client client}) => states;
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
}
