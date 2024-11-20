import 'package:fluffychat/di/global/dio_cache_interceptor_for_client.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/recovery_words/recovery_words.dart';
import 'package:fluffychat/domain/usecase/recovery/delete_recovery_words_interactor.dart';
import 'package:fluffychat/domain/usecase/recovery/get_recovery_words_interactor.dart';
import 'package:fluffychat/domain/usecase/recovery/save_recovery_words_interactor.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog_mobile_view.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog_style.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog_web_view.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';

class TomBootstrapDialog extends StatefulWidget {
  final Client client;
  final bool wipe;
  final bool wipeRecovery;

  const TomBootstrapDialog({
    super.key,
    required this.client,
    this.wipe = false,
    this.wipeRecovery = false,
  });

  Future<bool?> show(BuildContext context) => TwakeDialog.showDialogFullScreen(
        builder: () => this,
        barrierColor: TomBootstrapDialogStyle.barrierColor(context),
      );

  @override
  TomBootstrapDialogState createState() => TomBootstrapDialogState();
}

class TomBootstrapDialogState extends State<TomBootstrapDialog>
    with TickerProviderStateMixin {
  final _saveRecoveryWordsInteractor = getIt.get<SaveRecoveryWordsInteractor>();

  final _getRecoveryWordsInteractor = getIt.get<GetRecoveryWordsInteractor>();

  final _deleteRecoveryWordsInteractor =
      getIt.get<DeleteRecoveryWordsInteractor>();

  static const breakpointMobileDialogKey = Key('BreakPointMobileDialog');

  static const breakpointWebAndDesktopDialogKey =
      Key('BreakpointWebAndDesktopKeyDialog');

  static const Duration getRecoveryWordsDelay = Duration(seconds: 5);

  Bootstrap? bootstrap;

  UploadRecoveryKeyState _uploadRecoveryKeyState =
      UploadRecoveryKeyState.dataLoading;

  bool _wipe = false;
  RecoveryWords? _recoveryWords;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Matrix.of(context).showToMBootstrap.value = true;

      await _loadingData();
    });
  }

  Future<void> setupAdditionalDioCacheOption(String userId) async {
    Logs().i('TomBootstrapDialog::setupAdditionalDioCacheOption: $userId');
    DioCacheInterceptorForClient(userId).setup(getIt);
  }

  Future<RecoveryWords?> _getRecoveryWords() async {
    final result = await _getRecoveryWordsInteractor.execute();
    return result.fold(
      (failure) => null,
      (success) => success.words,
    );
  }

  Future<void> _loadingData() async {
    _uploadRecoveryKeyState = UploadRecoveryKeyState.dataLoading;
    Logs().i('_loadingData: $_uploadRecoveryKeyState');
    await widget.client.roomsLoading;
    await widget.client.accountDataLoading;

    Logs().i('_loadingData: roomDataLoaded & accountDataLoaded');
    if (widget.client.userID != null) {
      await setupAdditionalDioCacheOption(widget.client.userID!);
    }
    if (widget.wipeRecovery) {
      setState(() {
        _uploadRecoveryKeyState = UploadRecoveryKeyState.wipeRecovery;
        _wipe = widget.wipe;
      });
    } else {
      setState(() {
        _uploadRecoveryKeyState = UploadRecoveryKeyState.checkingRecoveryWork;
      });
      await _getRecoveryKeyState();
    }
  }

  Future<void> _getRecoveryKeyState() async {
    await widget.client.onSync.stream.first;
    await widget.client.initCompleter?.future;

    // Display first login bootstrap if enabled
    if (widget.client.encryption?.keyManager.enabled == true) {
      Logs().i(
        'TomBootstrapDialog::_initializeRecoveryKeyState: Showing bootstrap dialog when encryption is enabled',
      );
      if (await widget.client.encryption?.keyManager.isCached() == false ||
          await widget.client.encryption?.crossSigning.isCached() == false ||
          widget.client.isUnknownSession && mounted) {
        final recoveryWords = await _getRecoveryWords();
        _createBootstrap();
        if (recoveryWords != null) {
          _recoveryWords = recoveryWords;
          _uploadRecoveryKeyState = UploadRecoveryKeyState.useExisting;
          setState(() {});
          return;
        } else {
          Logs().i(
            'TomBootstrapDialog::_initializeRecoveryKeyState(): no recovery existed then call bootstrap',
          );

          Future.delayed(
            getRecoveryWordsDelay,
            () {
              Matrix.of(context).showToMBootstrap.value = false;
              Navigator.of(context, rootNavigator: false).pop<bool>(false);
            },
          );
        }
      }
    } else {
      Logs().i(
        'TomBootstrapDialog::_initializeRecoveryKeyState(): encryption is not enabled',
      );
      final recoveryWords = await _getRecoveryWords();
      _createBootstrap();
      _wipe = recoveryWords != null;
      if (recoveryWords != null) {
        _uploadRecoveryKeyState = UploadRecoveryKeyState.wipeRecovery;
      } else {
        _uploadRecoveryKeyState = UploadRecoveryKeyState.initial;
      }
      setState(() {});
      return;
    }
  }

  void _createBootstrap() {
    bootstrap =
        widget.client.encryption!.bootstrap(onUpdate: (_) => setState(() {}));
  }

  bool get isDataLoadingState =>
      _uploadRecoveryKeyState == UploadRecoveryKeyState.dataLoading;

  bool get isCheckingRecoveryWorkState =>
      _uploadRecoveryKeyState == UploadRecoveryKeyState.checkingRecoveryWork;

  String get _description {
    if (isDataLoadingState) {
      return L10n.of(context)!.backingUpYourMessage;
    } else if (isCheckingRecoveryWorkState) {
      return L10n.of(context)!.configureDataEncryption;
    } else {
      return L10n.of(context)!.recoveringYourEncryptedChats;
    }
  }

  @override
  Widget build(BuildContext context) {
    Logs().i(
      'TomBootstrapDialogState::build(): BootstrapState = ${bootstrap?.state}',
    );

    Logs().i(
      'TomBootstrapDialogState::build(): RecoveryKeyState = $_uploadRecoveryKeyState',
    );

    switch (_uploadRecoveryKeyState) {
      case UploadRecoveryKeyState.dataLoading:
        break;
      case UploadRecoveryKeyState.checkingRecoveryWork:
        break;
      case UploadRecoveryKeyState.wipeRecovery:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _wipeRecoveryWord();
        });
        break;
      case UploadRecoveryKeyState.wipeRecoveryFailed:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          TwakeSnackBar.show(context, L10n.of(context)!.cannotEnableKeyBackup);
          Matrix.of(context).showToMBootstrap.value = false;

          Navigator.of(context, rootNavigator: false).pop<bool>();
        });
        break;
      case UploadRecoveryKeyState.created:
        if (_createNewRecoveryKeySuccess()) {
          Logs().i(
            'TomBootstrapDialogState::build(): start backup process with key ${bootstrap?.newSsssKey!.recoveryKey}',
          );
          final key = bootstrap?.newSsssKey!.recoveryKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Logs().i(
              'TomBootstrapDialogState::build(): check if key is already in TOM = ${_existedRecoveryWordsInTom(
                key,
              )} - ${_recoveryWords?.words}',
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
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          Matrix.of(context).showToMBootstrap.value = false;

          Navigator.of(context, rootNavigator: false).pop<bool>(false);
        });
        break;
      case UploadRecoveryKeyState.uploadError:
        Logs().i('TomBootstrapDialogState::build(): upload recovery key error');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Matrix.of(context).showToMBootstrap.value = false;

          Navigator.of(context, rootNavigator: false).pop<bool>();
        });
        break;
      default:
        _handleBootstrapState();
        break;
    }

    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        const WidthPlatformBreakpoint(
          end: ResponsiveUtils.maxMobileWidth,
        ): SlotLayout.from(
          key: breakpointMobileDialogKey,
          builder: (_) => TomBootstrapDialogMobileView(
            description: _description,
          ),
        ),
        const WidthPlatformBreakpoint(
          begin: ResponsiveUtils.minTabletWidth,
        ): SlotLayout.from(
          key: breakpointWebAndDesktopDialogKey,
          builder: (_) => TomBootstrapDialogWebView(
            description: _description,
          ),
        ),
      },
    );
  }

  bool _existedRecoveryWordsInTom(String? key) {
    Logs().i(
      'TomBootstrapDialogState::_existedRecoveryWordsInTom(): $key, $_recoveryWords',
    );
    if (key == null && _recoveryWords != null) {
      return true;
    }
    return _recoveryWords != null && _recoveryWords!.words == key;
  }

  bool _createNewRecoveryKeySuccess() {
    return bootstrap?.newSsssKey?.recoveryKey != null &&
        _uploadRecoveryKeyState == UploadRecoveryKeyState.created;
  }

  bool get _setUpSuccess =>
      _uploadRecoveryKeyState != UploadRecoveryKeyState.dataLoading &&
      _uploadRecoveryKeyState != UploadRecoveryKeyState.checkingRecoveryWork;

  void _handleBootstrapState() {
    Logs().i(
      'TomBootstrapDialogState::_handleBootstrapState(): ${bootstrap?.state}',
    );
    if (bootstrap != null && _setUpSuccess) {
      switch (bootstrap!.state) {
        case BootstrapState.loading:
          break;
        case BootstrapState.askWipeSsss:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap?.wipeSsss(_wipe),
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
            (_) => bootstrap?.useExistingSsss(!_wipe),
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
            (_) => bootstrap?.wipeCrossSigning(_wipe),
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
            (_) => bootstrap?.wipeOnlineKeyBackup(_wipe),
          );
          break;
        case BootstrapState.askSetupOnlineKeyBackup:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap?.askSetupOnlineKeyBackup(true),
          );
          break;
        case BootstrapState.error:
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Matrix.of(context).showToMBootstrap.value = false;
            Navigator.of(context, rootNavigator: false).pop<bool>();
          });
          break;
        case BootstrapState.done:
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Matrix.of(context).showToMBootstrap.value = false;
            Navigator.of(context, rootNavigator: false).pop<bool>(true);
          });
          break;
      }
    }
  }

  Future<void> _wipeRecoveryWord() async {
    await _deleteRecoveryWordsInteractor.execute().then((either) {
      _createBootstrap();
      either.fold(
        (failure) {
          Logs().i(
            'TomBootstrapDialogState::_wipeRecoveryWord(): wipe recoveryWords failed',
          );
          if (Matrix.of(context).twakeSupported) {
            setState(
              () => _uploadRecoveryKeyState =
                  UploadRecoveryKeyState.wipeRecoveryFailed,
            );
          } else {
            setState(
              () => _uploadRecoveryKeyState = UploadRecoveryKeyState.initial,
            );
          }
        },
        (success) => setState(() {
          _uploadRecoveryKeyState = UploadRecoveryKeyState.initial;
        }),
      );
    });
  }

  Future<void> _backUpInRecoveryVault(String? key) async {
    if (key == null) {
      setState(() {
        Logs().i(
          'TomBootstrapDialogState::_backUpInRecoveryVault(): key null, upload failed',
        );
        _uploadRecoveryKeyState = UploadRecoveryKeyState.uploadError;
      });
    }
    await _saveRecoveryWordsInteractor.execute(key!).then(
          (either) => either.fold(
            (failure) {
              Logs().i(
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
    final recoveryWords = _recoveryWords;
    if (recoveryWords == null) {
      Logs().i('TomBootstrapDialogState::_unlockBackUp(): recoveryWords null');
      setState(() {
        _uploadRecoveryKeyState = UploadRecoveryKeyState.unlockError;
      });
      return;
    }
    try {
      Logs().i(
        'TomBootstrapDialogState::_unlockBackUp() unlocking: ${recoveryWords.words}',
      );
      await bootstrap?.newSsssKey!.unlock(
        keyOrPassphrase: recoveryWords.words,
      );
      Logs().i('TomBootstrapDialogState::_unlockBackUp() self Signing');
      await bootstrap?.client.encryption!.crossSigning.selfSign(
        keyOrPassphrase: recoveryWords.words,
      );
      Logs().i('TomBootstrapDialogState::_unlockBackUp() open existing SSSS');
      await bootstrap?.openExistingSsss();
    } catch (e, s) {
      Logs().w(
        'TomBootstrapDialogState::_unlockBackUp() Unable to unlock SSSS',
        e,
        s,
      );
      if (e is InvalidPassphraseException) {
        Logs().i(
          'TomBootstrapDialogState::_unlockBackUp(): InvalidPassphraseException: ${e.cause}',
        );
      }
      setState(() {
        _uploadRecoveryKeyState = UploadRecoveryKeyState.unlockError;
      });
    } finally {
      setState(() {});
    }
  }
}

enum UploadRecoveryKeyState {
  dataLoading,
  checkingRecoveryWork,
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
