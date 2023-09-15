import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/recovery_words/recovery_words.dart';
import 'package:fluffychat/domain/usecase/recovery/delete_recovery_words_interactor.dart';
import 'package:fluffychat/domain/usecase/recovery/save_recovery_words_interactor.dart';
import 'package:fluffychat/widgets/adaptive_flat_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/encryption/utils/bootstrap.dart';
import 'package:matrix/matrix.dart';

import 'bootstrap_dialog.dart';

class TomBootstrapDialog extends StatefulWidget {
  final bool wipe;
  final bool wipeRecovery;
  final Client client;
  final RecoveryWords? recoveryWords;

  const TomBootstrapDialog({
    Key? key,
    this.recoveryWords,
    this.wipe = false,
    this.wipeRecovery = false,
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
  final _deleteRecoveryWordsInteractor =
      getIt.get<DeleteRecoveryWordsInteractor>();
  Bootstrap? bootstrap;

  String? titleText;
  Widget? body;
  final buttons = <AdaptiveFlatButton>[];

  UploadRecoveryKeyState _uploadRecoveryKeyState =
      UploadRecoveryKeyState.initial;

  bool? _wipe;

  @override
  void initState() {
    super.initState();
    _createBootstrap(widget.wipe);
  }

  void _createBootstrap(bool wipe) async {
    _wipe = wipe;
    titleText = null;
    _uploadRecoveryKeyState = _initializeRecoveryKeyState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bootstrap =
          widget.client.encryption!.bootstrap(onUpdate: (_) => setState(() {}));
    });
  }

  UploadRecoveryKeyState _initializeRecoveryKeyState() {
    if (widget.wipeRecovery) {
      return UploadRecoveryKeyState.wipeRecovery;
    }

    if (widget.recoveryWords != null) {
      return UploadRecoveryKeyState.useExisting;
    }

    return UploadRecoveryKeyState.initial;
  }

  @override
  Widget build(BuildContext context) {
    Logs().d(
      'TomBootstrapDialogState::build(): BootstrapState = ${bootstrap?.state}',
    );
    _wipe ??= widget.wipe;
    body = _loadingContent(context);

    switch (_uploadRecoveryKeyState) {
      case UploadRecoveryKeyState.wipeRecovery:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _wipeRecoveryWord();
        });
        break;
      case UploadRecoveryKeyState.wipeRecoveryFailed:
        titleText = L10n.of(context)!.chatBackup;
        body = Text(
          L10n.of(context)!.cannotEnableKeyBackup,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        );
        buttons.clear();
        buttons.add(
          AdaptiveFlatButton(
            label: L10n.of(context)!.close,
            onPressed: () =>
                Navigator.of(context, rootNavigator: false).pop<bool>(false),
          ),
        );
        break;
      case UploadRecoveryKeyState.created:
        if (_createNewRecoveryKeySuccess()) {
          Logs().d(
            'TomBootstrapDialogState::build(): start backup process with key ${bootstrap?.newSsssKey!.recoveryKey}',
          );
          final key = bootstrap?.newSsssKey!.recoveryKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Logs().d(
              'TomBootstrapDialogState::build(): check if key is already in TOM = ${_existedRecoveryWordsInTom(
                key,
              )} - ${widget.recoveryWords?.words}',
            );
            if (_existedRecoveryWordsInTom(key)) {
              _uploadRecoveryKeyState = UploadRecoveryKeyState.uploaded;
              return;
            }
            _backUpInRecoveryVault(key);
          });
        }
        break;
      case UploadRecoveryKeyState.uploaded:
        _handleBootstrapState();
        break;
      case UploadRecoveryKeyState.useExisting:
        _handleBootstrapState();
        break;
      case UploadRecoveryKeyState.unlockError:
        titleText = L10n.of(context)!.chatBackup;
        body = Text(
          L10n.of(context)!.cannotUnlockBackupKey,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        );
        buttons.clear();
        buttons
          ..add(
            AdaptiveFlatButton(
              label: L10n.of(context)!.close,
              onPressed: () =>
                  Navigator.of(context, rootNavigator: false).pop<bool>(false),
            ),
          )
          ..add(
            AdaptiveFlatButton(
              label: L10n.of(context)!.next,
              onPressed: () async {
                await BootstrapDialog(client: widget.client).show(context).then(
                      (value) => Navigator.of(context, rootNavigator: false)
                          .pop<bool>(false),
                    );
              },
            ),
          );
        break;
      case UploadRecoveryKeyState.uploadError:
        Logs().e('TomBootstrapDialogState::build(): upload recovery key error');
        titleText = L10n.of(context)!.chatBackup;
        body = Text(
          L10n.of(context)!.cannotUploadKey,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        );
        buttons.clear();
        buttons.add(
          AdaptiveFlatButton(
            label: L10n.of(context)!.close,
            onPressed: () =>
                Navigator.of(context, rootNavigator: false).pop<bool>(false),
          ),
        );
        break;
      default:
        _handleBootstrapState();
        break;
    }

    return AlertDialog(
      title: titleText != null ? Text(titleText!) : null,
      content: body,
      actions: buttons,
    );
  }

  bool _existedRecoveryWordsInTom(String? key) {
    if (key == null && widget.recoveryWords != null) {
      return true;
    }
    return widget.recoveryWords != null && widget.recoveryWords!.words == key;
  }

  bool _createNewRecoveryKeySuccess() {
    return bootstrap?.newSsssKey?.recoveryKey != null &&
        _uploadRecoveryKeyState == UploadRecoveryKeyState.created;
  }

  void _handleBootstrapState() {
    if (bootstrap != null) {
      switch (bootstrap!.state) {
        case BootstrapState.loading:
          break;
        case BootstrapState.askWipeSsss:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap?.wipeSsss(_wipe!),
          );
          break;
        case BootstrapState.askBadSsss:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap?.ignoreBadSecrets(true),
          );
          break;
        case BootstrapState.askUseExistingSsss:
          _uploadRecoveryKeyState = UploadRecoveryKeyState.useExisting;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap?.useExistingSsss(!_wipe!),
          );
          break;
        case BootstrapState.askUnlockSsss:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap?.unlockedSsss(),
          );
          break;
        case BootstrapState.askNewSsss:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap?.newSsss().then(
                  (_) =>
                      _uploadRecoveryKeyState = UploadRecoveryKeyState.created,
                ),
          );
          break;
        case BootstrapState.openExistingSsss:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _unlockBackUp(),
          );
          break;
        case BootstrapState.askWipeCrossSigning:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap?.wipeCrossSigning(_wipe!),
          );
          break;
        case BootstrapState.askSetupCrossSigning:
          _uploadRecoveryKeyState =
              UploadRecoveryKeyState.uploadingCrossSigningKeys;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap?.askSetupCrossSigning(
              setupMasterKey: true,
              setupSelfSigningKey: true,
              setupUserSigningKey: true,
            ),
          );
          break;
        case BootstrapState.askWipeOnlineKeyBackup:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap?.wipeOnlineKeyBackup(_wipe!),
          );
          break;
        case BootstrapState.askSetupOnlineKeyBackup:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap?.askSetupOnlineKeyBackup(true),
          );
          break;
        case BootstrapState.error:
          titleText = L10n.of(context)!.oopsSomethingWentWrong;
          body = const Icon(Icons.error_outline, color: Colors.red, size: 40);
          buttons.clear();
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
          buttons.clear();
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
  }

  Future<void> _wipeRecoveryWord() async {
    await _deleteRecoveryWordsInteractor.execute().then(
          (either) => either.fold(
            (failure) {
              Logs().e(
                'TomBootstrapDialogState::_wipeRecoveryWord(): wipe recoveryWords failed',
              );
              setState(
                () => _uploadRecoveryKeyState =
                    UploadRecoveryKeyState.wipeRecoveryFailed,
              );
            },
            (success) => setState(
              () => _uploadRecoveryKeyState = UploadRecoveryKeyState.initial,
            ),
          ),
        );
  }

  Future<void> _backUpInRecoveryVault(String? key) async {
    if (key == null) {
      setState(() {
        Logs().d(
          'TomBootstrapDialogState::_backUpInRecoveryVault(): key null, upload failed',
        );
        _uploadRecoveryKeyState = UploadRecoveryKeyState.uploadError;
      });
    }
    await _saveRecoveryWordsInteractor.execute(key!).then(
          (either) => either.fold(
            (failure) {
              Logs().d(
                'TomBootstrapDialogState::_backUpInRecoveryVault(): upload recoveryWords failed',
              );
              setState(
                () => _uploadRecoveryKeyState =
                    UploadRecoveryKeyState.uploadError,
              );
            },
            (success) => setState(
              () => _uploadRecoveryKeyState = UploadRecoveryKeyState.uploaded,
            ),
          ),
        );
  }

  Future<void> _unlockBackUp() async {
    final recoveryWords = widget.recoveryWords;
    if (recoveryWords == null) {
      Logs().e('TomBootstrapDialogState::_unlockBackUp(): recoveryWords null');
      setState(() {
        _uploadRecoveryKeyState = UploadRecoveryKeyState.unlockError;
      });
      return;
    }
    try {
      Logs().d('TomBootstrapDialogState::_unlockBackUp() unlocking');
      await bootstrap?.newSsssKey!.unlock(
        keyOrPassphrase: recoveryWords.words,
      );
      Logs().d('TomBootstrapDialogState::_unlockBackUp() self Signing');
      await bootstrap?.client.encryption!.crossSigning.selfSign(
        keyOrPassphrase: recoveryWords.words,
      );
      Logs().d('TomBootstrapDialogState::_unlockBackUp() open existing SSSS');
      await bootstrap?.openExistingSsss();
    } catch (e, s) {
      Logs().w(
        'TomBootstrapDialogState::_unlockBackUp() Unable to unlock SSSS',
        e,
        s,
      );
      setState(() {
        _uploadRecoveryKeyState = UploadRecoveryKeyState.unlockError;
      });
    } finally {
      setState(() {});
    }
  }

  Widget _loadingContent(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: CircularProgressIndicator.adaptive(),
        ),
        Expanded(
          child: Text(
            L10n.of(context)!.loadingPleaseWait,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

enum UploadRecoveryKeyState {
  initial,
  wipeRecovery,
  wipeRecoveryFailed,
  created,
  uploadingCrossSigningKeys,
  uploaded,
  uploadError,
  useExisting,
  unlockError,
}
