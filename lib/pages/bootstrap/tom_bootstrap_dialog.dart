import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/recovery_words/recovery_words.dart';
import 'package:fluffychat/domain/usecases/save_recovery_words_interactor.dart';
import 'package:fluffychat/widgets/adaptive_flat_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/encryption/utils/bootstrap.dart';
import 'package:matrix/matrix.dart';

class TomBootstrapDialog extends StatefulWidget {
  final bool wipe;
  final Client client;
  final RecoveryWords? recoveryWords;
  const TomBootstrapDialog({
    Key? key,
    this.recoveryWords,
    this.wipe = false,
    required this.client,
  }) : super(key: key);

  Future<bool?> show(BuildContext context) => showDialog(
    context: context,
    builder: (context) => this,
    barrierDismissible: true,
    useRootNavigator: false,
  );

  @override
  TomBootstrapDialogState createState() => TomBootstrapDialogState();
}

class TomBootstrapDialogState extends State<TomBootstrapDialog> {

  final _saveRecoveryWordsInteractor = getIt.get<SaveRecoveryWordsInteractor>();
  late Bootstrap bootstrap;
  String? titleText;

  UploadRecoveryKeyState _uploadRecoveryKeyState = UploadRecoveryKeyState.initial;

  bool? _wipe;

  @override
  void initState() {
    _createBootstrap(widget.wipe);
    super.initState();
  }

  void _createBootstrap(bool wipe) async {
    _wipe = wipe;
    titleText = null;
    _uploadRecoveryKeyState = UploadRecoveryKeyState.initial;
    bootstrap =
        widget.client.encryption!.bootstrap(onUpdate: (_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    Logs().d('TomBootstrapDialogState::build(): BootstrapState = ${bootstrap.state}');
    _wipe ??= widget.wipe;
    final buttons = <AdaptiveFlatButton>[];
    Widget body = const LinearProgressIndicator();
    titleText = L10n.of(context)!.loadingPleaseWait;

    if (bootstrap.newSsssKey?.recoveryKey != null &&
        _uploadRecoveryKeyState == UploadRecoveryKeyState.initial) {
      Logs().d('TomBootstrapDialogState::build(): start backup process with key ${bootstrap.newSsssKey!.recoveryKey}');
      final key = bootstrap.newSsssKey!.recoveryKey;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _backUpInRecoveryVault(key),
      );
    } else {
      switch (bootstrap.state) {
        case BootstrapState.loading:
          break;
        case BootstrapState.askWipeSsss:
          WidgetsBinding.instance.addPostFrameCallback(
                (_) => bootstrap.wipeSsss(_wipe!),
          );
          break;
        case BootstrapState.askBadSsss:
          WidgetsBinding.instance.addPostFrameCallback(
                (_) => bootstrap.ignoreBadSecrets(true),
          );
          break;
        case BootstrapState.askUseExistingSsss:
          _uploadRecoveryKeyState = UploadRecoveryKeyState.useExisting;
          WidgetsBinding.instance.addPostFrameCallback(
                (_) => bootstrap.useExistingSsss(!_wipe!),
          );
          break;
        case BootstrapState.askUnlockSsss:
          WidgetsBinding.instance.addPostFrameCallback(
                (_) => bootstrap.unlockedSsss(),
          );
          break;
        case BootstrapState.askNewSsss:
          WidgetsBinding.instance.addPostFrameCallback(
                (_) => bootstrap.newSsss(),
          );
          break;
        case BootstrapState.openExistingSsss:
          WidgetsBinding.instance.addPostFrameCallback(
                (_) => _unlockBackUp(),
          );
          break;
        case BootstrapState.askWipeCrossSigning:
          WidgetsBinding.instance.addPostFrameCallback(
                (_) => bootstrap.wipeCrossSigning(_wipe!),
          );
          break;
        case BootstrapState.askSetupCrossSigning:
          WidgetsBinding.instance.addPostFrameCallback(
                (_) => bootstrap.askSetupCrossSigning(
              setupMasterKey: true,
              setupSelfSigningKey: true,
              setupUserSigningKey: true,
            ),
          );
          break;
        case BootstrapState.askWipeOnlineKeyBackup:
          WidgetsBinding.instance.addPostFrameCallback(
                (_) => bootstrap.wipeOnlineKeyBackup(_wipe!),
          );

          break;
        case BootstrapState.askSetupOnlineKeyBackup:
          WidgetsBinding.instance.addPostFrameCallback(
                (_) => bootstrap.askSetupOnlineKeyBackup(true),
          );
          break;
        case BootstrapState.error:
          titleText = L10n.of(context)!.oopsSomethingWentWrong;
          body = const Icon(Icons.error_outline, color: Colors.red, size: 40);
          buttons.add(
            AdaptiveFlatButton(
              label: L10n.of(context)!.close,
              onPressed: () =>
                  Navigator.of(context, rootNavigator: false).pop<bool>(false),
            ),
          );
          break;
        case BootstrapState.done:
          titleText = L10n.of(context)!.everythingReady;
          body = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/backup.png', fit: BoxFit.contain),
              Text(L10n.of(context)!.yourChatBackupHasBeenSetUp),
            ],
          );
          buttons.add(
            AdaptiveFlatButton(
              label: L10n.of(context)!.close,
              onPressed: () =>
                  Navigator.of(context, rootNavigator: false).pop<bool>(false),
            ),
          );
          break;
      }
    }

    final title = Text(titleText!);
    return AlertDialog(
      title: title,
      content: body,
      actions: buttons,
    );
  }

  Future<void> _backUpInRecoveryVault(String? key) async {
    if (key == null) {
      setState(() {
        Logs().d('TomBootstrapDialogState::_backUpInRecoveryVault(): key null, upload failed');
        _uploadRecoveryKeyState = UploadRecoveryKeyState.error;
      });
    }
    await _saveRecoveryWordsInteractor.execute(key!)
      .then((either) => either
        .fold(
          (failure) {
            Logs().d('TomBootstrapDialogState::_backUpInRecoveryVault(): upload recoveryWords failed');
            setState(() => _uploadRecoveryKeyState = UploadRecoveryKeyState.error);
          },
          (success) => setState(() => _uploadRecoveryKeyState = UploadRecoveryKeyState.uploaded),
        ),
      );
  }

  Future<void> _unlockBackUp() async {
    final recoveryWords = widget.recoveryWords;
    if (recoveryWords == null) {
      // error handling
      return;
    }
    try {
      await bootstrap.newSsssKey!.unlock(
        keyOrPassphrase: recoveryWords.words,
      );
      Logs().d('SSSS unlocked');
      await bootstrap.client.encryption!.crossSigning
          .selfSign(
        keyOrPassphrase: recoveryWords.words,
      );
      Logs().d('Successful elfsigned');
      await bootstrap.openExistingSsss();
    } catch (e, s) {
      Logs().w('Unable to unlock SSSS', e, s);
      setState(
        () => titleText = L10n.of(context)!.oopsSomethingWentWrong,
      );
    } finally {
      setState(() {});
    }
  }
}

enum UploadRecoveryKeyState {
  initial,
  uploaded,
  error,
  useExisting,
}
