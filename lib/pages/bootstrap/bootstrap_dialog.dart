import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/adaptive_flat_button.dart';
import 'package:fluffychat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:matrix/encryption.dart';
import 'package:matrix/encryption/utils/bootstrap.dart';
import 'package:matrix/matrix.dart';
import 'package:share_plus/share_plus.dart';

class BootstrapDialog extends StatefulWidget {
  final bool wipe;
  final Client client;

  const BootstrapDialog({
    super.key,
    this.wipe = false,
    required this.client,
  });

  Future<bool?> show() => PlatformInfos.isCupertinoStyle
      ? TwakeDialog.showCupertinoDialogFullScreen(
          builder: () => this,
        )
      : TwakeDialog.showDialogFullScreen(
          builder: () => this,
        );

  @override
  BootstrapDialogState createState() => BootstrapDialogState();
}

class BootstrapDialogState extends State<BootstrapDialog> {
  final TextEditingController _recoveryKeyTextEditingController =
      TextEditingController();

  late Bootstrap bootstrap;

  String? _recoveryKeyInputError;

  bool _recoveryKeyInputLoading = false;

  String? titleText;

  bool _recoveryKeyStored = false;
  bool _recoveryKeyCopied = false;

  bool? _storeInSecureStorage = false;

  bool? _wipe;

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

  void _createBootstrap(bool wipe) async {
    _wipe = wipe;
    titleText = null;
    _recoveryKeyStored = false;
    bootstrap =
        widget.client.encryption!.bootstrap(onUpdate: (_) => setState(() {}));
    final key = await const FlutterSecureStorage().read(key: _secureStorageKey);
    if (key == null) return;
    _recoveryKeyTextEditingController.text = key;
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
            constraints:
                const BoxConstraints(maxWidth: TwakeThemes.columnWidth * 1.5),
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
                const Divider(
                  height: 32,
                  thickness: 1,
                ),
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
                    subtitle:
                        Text(L10n.of(context)!.storeInSecureStorageDescription),
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
          _recoveryKeyStored = true;
          return Scaffold(
            appBar: AppBar(
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              title: Text(L10n.of(context)!.chatBackup),
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
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8.0),
                      trailing: Icon(
                        Icons.info_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      subtitle: Text(
                        L10n.of(context)!.pleaseEnterRecoveryKeyDescription,
                      ),
                    ),
                    const Divider(height: 32),
                    TextField(
                      minLines: 1,
                      maxLines: 2,
                      autocorrect: false,
                      readOnly: _recoveryKeyInputLoading,
                      contextMenuBuilder: mobileTwakeContextMenuBuilder,
                      autofillHints: _recoveryKeyInputLoading
                          ? null
                          : [AutofillHints.password],
                      controller: _recoveryKeyTextEditingController,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(16),
                        hintStyle: const TextStyle(
                          fontFamily: 'Inter',
                        ),
                        hintText: L10n.of(context)!.recoveryKey,
                        errorText: _recoveryKeyInputError,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      icon: _recoveryKeyInputLoading
                          ? const CircularProgressIndicator.adaptive()
                          : const Icon(Icons.lock_open_outlined),
                      label: Text(L10n.of(context)!.unlockOldMessages),
                      onPressed: _recoveryKeyInputLoading
                          ? null
                          : () async {
                              setState(() {
                                _recoveryKeyInputError = null;
                                _recoveryKeyInputLoading = true;
                              });
                              try {
                                final key =
                                    _recoveryKeyTextEditingController.text;
                                await bootstrap.newSsssKey!.unlock(
                                  keyOrPassphrase: key,
                                );
                                Logs().d('SSSS unlocked');
                                await bootstrap.client.encryption!.crossSigning
                                    .selfSign(
                                  keyOrPassphrase: key,
                                );
                                Logs().d('Successful elfsigned');
                                await bootstrap.openExistingSsss();
                              } catch (e, s) {
                                Logs().w('Unable to unlock SSSS', e, s);
                                setState(
                                  () => _recoveryKeyInputError =
                                      L10n.of(context)!.oopsSomethingWentWrong,
                                );
                              } finally {
                                setState(
                                  () => _recoveryKeyInputLoading = false,
                                );
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(L10n.of(context)!.or),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    // TODO: TW-1766: temporary disable right now, because not supported yet
                    // const SizedBox(height: 16),
                    // ElevatedButton.icon(
                    //   icon: const Icon(Icons.cast_connected_outlined),
                    //   label: Text(L10n.of(context)!.transferFromAnotherDevice),
                    //   onPressed: _recoveryKeyInputLoading
                    //       ? null
                    //       : () async {
                    //           final req = await TwakeDialog
                    //               .showFutureLoadingDialogFullScreen(
                    //             future: () => widget.client
                    //                 .userDeviceKeys[widget.client.userID!]!
                    //                 .startVerification(),
                    //           );
                    //           if (req.error != null) return;
                    //           await KeyVerificationDialog(request: req.result!)
                    //               .show(context);
                    //           Navigator.of(context, rootNavigator: false).pop();
                    //         },
                    // ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      icon: const Icon(Icons.delete_outlined),
                      label: Text(L10n.of(context)!.recoveryKeyLost),
                      onPressed: _recoveryKeyInputLoading
                          ? null
                          : () async {
                              if (OkCancelResult.ok ==
                                  await showOkCancelAlertDialog(
                                    useRootNavigator: false,
                                    context: context,
                                    title: L10n.of(context)!.recoveryKeyLost,
                                    message: L10n.of(context)!.wipeChatBackup,
                                    okLabel: L10n.of(context)!.ok,
                                    cancelLabel: L10n.of(context)!.cancel,
                                    isDestructiveAction: true,
                                  )) {
                                if (Matrix.of(context).twakeSupported) {
                                  await TomBootstrapDialog(
                                    client: widget.client,
                                    wipe: true,
                                    wipeRecovery: true,
                                  ).show(context).then(
                                        (value) => Navigator.of(
                                          context,
                                          rootNavigator: false,
                                        ).pop<bool>(false),
                                      );
                                } else {
                                  _createBootstrap(true);
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          );
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
            Expanded(
              child: Text(
                titleText!,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      actions: buttons.isNotEmpty ? buttons : null,
    );
  }
}
