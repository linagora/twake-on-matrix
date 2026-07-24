import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/domain/keychain_sharing/keychain_sharing_manager.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_option.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_screen.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/adaptive_flat_button.dart';
import 'package:fluffychat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:matrix/encryption.dart';
import 'package:matrix/encryption/utils/bootstrap.dart';
import 'package:matrix/matrix.dart';
import 'package:share_plus/share_plus.dart';

class BootstrapDialog extends StatefulWidget {
  final bool wipe;
  final Client client;

  const BootstrapDialog({super.key, this.wipe = false, required this.client});

  Future<bool?> show() => PlatformInfos.isCupertinoStyle
      ? TwakeDialog.showCupertinoDialogFullScreen(builder: () => this)
      : TwakeDialog.showDialogFullScreen(builder: () => this);

  @override
  BootstrapDialogState createState() => BootstrapDialogState();
}

class BootstrapDialogState extends State<BootstrapDialog> {
  late Bootstrap bootstrap;

  String? titleText;

  bool _recoveryKeyStored = false;
  bool _recoveryKeyCopied = false;

  /// True once bootstrap has reached [BootstrapState.openExistingSsss] (the
  /// verify-device flow) — kept true through its later auto-driven states so
  /// the legacy dialog UI below never takes over mid-flow.
  bool _showVerifyDeviceScreen = false;

  /// True while re-running bootstrap via "Retry automatically" (issue #3218:
  /// forces another try of automatic setup) — if it reaches
  /// [BootstrapState.done], the chooser's own success view is shown instead
  /// of the legacy dialog, same as the recovery-key/verify-device flows.
  bool _isRetrying = false;

  bool? _storeInSecureStorage = false;

  bool? _wipe;

  String? _prefilledRecoveryKey;

  /// Set once a retry's automatic unlock attempt finishes, so the build
  /// below can show success/error instead of re-asking via the chooser.
  bool? _retrySucceeded;

  String get _secureStorageKey =>
      'ssss_recovery_key_${bootstrap.client.userID}';

  bool get _supportsSecureStorage =>
      PlatformInfos.isMobile || PlatformInfos.isDesktop;

  String _getSecureStorageLocalizedName() {
    if (PlatformInfos.isAndroid) {
      return L10n.of(context)!.storeInAndroidKeystore;
    }
    if (PlatformInfos.isIOS || PlatformInfos.isMacOS) {
      return L10n.of(context)!.storeInAppleKeyChain;
    }
    return L10n.of(context)!.storeSecurlyOnThisDevice;
  }

  @override
  void initState() {
    _createBootstrap(widget.wipe);
    super.initState();
  }

  void _createBootstrap(bool wipe, {bool isRetry = false}) async {
    _wipe = wipe;
    titleText = null;
    _recoveryKeyStored = false;
    // A retry is always triggered from the chooser (VerifyDeviceScreen), so
    // keep showing it while bootstrap re-runs — resetting this to false
    // would let the legacy AlertDialog below take over on every build until
    // bootstrap reaches a new state, hiding both progress and any error.
    _showVerifyDeviceScreen = isRetry || _showVerifyDeviceScreen;
    _isRetrying = isRetry;
    _retrySucceeded = null;
    bootstrap = widget.client.encryption!.bootstrap(
      onUpdate: (_) => setState(() {}),
    );
    final key = await const FlutterSecureStorage().read(key: _secureStorageKey);
    if (key == null) return;
    if (!mounted) return;
    setState(() => _prefilledRecoveryKey = key);
  }

  /// Unlocks SSSS with [recoveryKey] and completes cross-signing/key-backup
  /// setup, shared by the recovery-key form and the automatic retry path.
  Future<bool> _unlockWithRecoveryKey(String recoveryKey) async {
    try {
      await bootstrap.newSsssKey!.unlock(keyOrPassphrase: recoveryKey);
      Logs().d('SSSS unlocked');
      await bootstrap.client.encryption!.crossSigning.selfSign(
        keyOrPassphrase: recoveryKey,
      );
      Logs().d('Successful elfsigned');
      await bootstrap.openExistingSsss();
      await KeychainSharingManager.saveRecoveryKey(
        userId: bootstrap.client.userID,
        recoveryKey: recoveryKey,
      );
      return true;
    } catch (e, s) {
      Logs().w('Unable to unlock SSSS', e, s);
      return false;
    }
  }

  /// Auto-attempts unlocking with the cached recovery key when a retry
  /// reaches [BootstrapState.openExistingSsss] — without this, retry just
  /// re-lands on the same chooser screen it started from, looking like it
  /// did nothing. Falls straight to the error view when there's no cached
  /// key to retry with.
  void _autoRetryOpenExistingSsss() {
    final recoveryKey = _prefilledRecoveryKey;
    if (recoveryKey == null) {
      setState(() => _retrySucceeded = false);
      return;
    }
    _unlockWithRecoveryKey(recoveryKey).then((success) {
      if (!mounted) return;
      setState(() => _retrySucceeded = success);
    });
  }

  Widget _buildVerifyDeviceScreen(BuildContext context) {
    return VerifyDeviceScreen(
      onRetry: () => _createBootstrap(_wipe ?? false, isRetry: true),
      initialRecoveryKey: _prefilledRecoveryKey,
      initialSuccess:
          _isRetrying &&
          (_retrySucceeded == true || bootstrap.state == BootstrapState.done),
      initialError:
          _isRetrying &&
          (_retrySucceeded == false || bootstrap.state == BootstrapState.error),
      onStartVerification: () async {
        await widget.client.updateUserDeviceKeys();
        final deviceKeys = widget.client.userDeviceKeys[widget.client.userID];
        if (deviceKeys == null) return null;
        try {
          return await deviceKeys.startVerification();
        } catch (e, s) {
          Logs().w('Unable to start verification', e, s);
          return null;
        }
      },
      onVerifyRecoveryKey: _unlockWithRecoveryKey,
      onResetEncryption: () async {
        final result = await TomBootstrapDialog(
          client: widget.client,
          wipe: true,
          wipeRecovery: true,
        ).show(context);
        return result == true;
      },
      options: [
        VerifyDeviceOption(
          icon: Icons.smartphone_outlined,
          title: L10n.of(context)!.useAnotherDevice,
          subtitle: L10n.of(context)!.useAnotherDeviceDescription,
          isUseAnotherDevice: true,
        ),
        VerifyDeviceOption(
          icon: Icons.key_outlined,
          title: L10n.of(context)!.useRecoveryKeyTitle,
          subtitle: L10n.of(context)!.useRecoveryKeyDescription,
          isUseRecoveryKey: true,
        ),
        VerifyDeviceOption(
          icon: Icons.key_off_outlined,
          title: L10n.of(context)!.notPossibleToVerify,
          subtitle: L10n.of(context)!.notPossibleToVerifyDescription,
          isNotPossibleToVerify: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _wipe ??= widget.wipe;
    final buttons = <AdaptiveFlatButton>[];
    Widget body = const CircularProgressIndicator.adaptive();
    titleText = L10n.of(context)!.loadingPleaseWait;

    if (bootstrap.newSsssKey?.recoveryKey != null &&
        _recoveryKeyStored == false) {
      final key = bootstrap.newSsssKey!.recoveryKey;
      titleText = L10n.of(context)!.recoveryKey;
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          title: Text(L10n.of(context)!.recoveryKey),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: TwakeThemes.columnWidth * 1.5,
            ),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  trailing: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Icon(
                      Icons.info_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  subtitle: Text(L10n.of(context)!.chatBackupDescription),
                ),
                const Divider(height: 32, thickness: 1),
                TextField(
                  minLines: 2,
                  maxLines: 4,
                  readOnly: true,
                  style: Theme.of(context).textTheme.bodyMedium,
                  contextMenuBuilder: mobileTwakeContextMenuBuilder,
                  controller: TextEditingController(text: key),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(16),
                    suffixIcon: Icon(Icons.key_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                if (_supportsSecureStorage)
                  CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                    value: _storeInSecureStorage,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (b) {
                      setState(() {
                        _storeInSecureStorage = b;
                      });
                    },
                    title: Text(_getSecureStorageLocalizedName()),
                    subtitle: Text(
                      L10n.of(context)!.storeInSecureStorageDescription,
                    ),
                  ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  value: _recoveryKeyCopied,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (b) {
                    final box = context.findRenderObject() as RenderBox;
                    Share.share(
                      key!,
                      sharePositionOrigin:
                          box.localToGlobal(Offset.zero) & box.size,
                    );
                    setState(() => _recoveryKeyCopied = true);
                  },
                  title: Text(L10n.of(context)!.copyToClipboard),
                  subtitle: Text(L10n.of(context)!.saveKeyManuallyDescription),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_outlined),
                  label: Text(L10n.of(context)!.next),
                  onPressed:
                      (_recoveryKeyCopied || _storeInSecureStorage == true)
                      ? () {
                          if (_storeInSecureStorage == true) {
                            const FlutterSecureStorage().write(
                              key: _secureStorageKey,
                              value: key,
                            );
                          }
                          setState(() => _recoveryKeyStored = true);
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      switch (bootstrap.state) {
        case BootstrapState.loading:
          break;
        case BootstrapState.askWipeSsss:
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            bootstrap.wipeSsss(_wipe!);
          });
          break;
        case BootstrapState.askBadSsss:
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            bootstrap.ignoreBadSecrets(true);
          });
          break;
        case BootstrapState.askUseExistingSsss:
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            bootstrap.useExistingSsss(!_wipe!);
          });
          break;
        case BootstrapState.askUnlockSsss:
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            bootstrap.unlockedSsss();
          });
          break;
        case BootstrapState.askNewSsss:
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            bootstrap.newSsss();
          });
          break;
        case BootstrapState.openExistingSsss:
          _recoveryKeyStored = true;
          _showVerifyDeviceScreen = true;
          if (_isRetrying && _retrySucceeded == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _autoRetryOpenExistingSsss();
            });
          }
          break;
        case BootstrapState.askWipeCrossSigning:
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            bootstrap.wipeCrossSigning(_wipe!);
          });
          break;
        case BootstrapState.askSetupCrossSigning:
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            bootstrap.askSetupCrossSigning(
              setupMasterKey: true,
              setupSelfSigningKey: true,
              setupUserSigningKey: true,
            );
          });
          break;
        case BootstrapState.askWipeOnlineKeyBackup:
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            bootstrap.wipeOnlineKeyBackup(_wipe!);
          });

          break;
        case BootstrapState.askSetupOnlineKeyBackup:
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            bootstrap.askSetupOnlineKeyBackup(true);
          });
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
          titleText = null;
          body = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/backup.png', fit: BoxFit.contain),
              Flexible(
                child: Text(
                  L10n.of(context)!.yourChatBackupHasBeenSetUp,
                  textAlign: TextAlign.center,
                ),
              ),
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

    // Once the verify-device flow has started (or a "Retry automatically"
    // triggered from it is re-running bootstrap), keep showing this screen
    // through the rest of bootstrap's auto-driven states (cross-signing
    // setup, key backup, done/error) — those states advance on their own
    // via the addPostFrameCallback calls above, but the legacy AlertDialog
    // below must never take over mid-flow.
    if (_showVerifyDeviceScreen) {
      return _buildVerifyDeviceScreen(context);
    }

    return AlertDialog(
      content: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: body,
            ),
          ),
          if (titleText != null)
            Expanded(child: Text(titleText!, overflow: TextOverflow.ellipsis)),
        ],
      ),
      actions: buttons.isNotEmpty ? buttons : null,
    );
  }
}
