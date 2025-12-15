import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog_mobile_view.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog_web_view.dart';
import 'package:fluffychat/presentation/model/client_login_state_event.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/agruments/logged_in_body_args.dart';
import 'package:fluffychat/widgets/layouts/agruments/logged_in_other_account_body_args.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:matrix/matrix.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class InitClientDialog extends StatefulWidget {
  final Future Function() future;

  const InitClientDialog({
    super.key,
    required this.future,
  });

  @override
  State<InitClientDialog> createState() => _InitClientDialogState();
}

class _InitClientDialogState extends State<InitClientDialog>
    with TickerProviderStateMixin {
  late AnimationController loginSSOProgressController;

  Client? _clientFirstLoggedIn;

  Client? _clientAddAnotherAccount;

  StreamSubscription? _clientLoginStateChangedSubscription;

  static const breakpointMobileDialogKey =
      Key('BreakPointMobileInitClientDialog');

  static const breakpointWebAndDesktopDialogKey =
      Key('BreakpointWebAndDesktopKeyInitClientDialog');

  @override
  void initState() {
    _initial();
    _clientLoginStateChangedSubscription =
        Matrix.of(context).onClientLoginStateChanged.stream.listen(
              _listenClientLoginStateChanged,
            );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        _startLoginSSOProgress();
        await widget
            .future()
            .then(
              (_) => _handleFunctionOnDone(),
            )
            .onError(
              (error, _) => _handleFunctionOnError(error),
            );
      },
    );

    super.initState();
  }

  void _listenClientLoginStateChanged(ClientLoginStateEvent event) {
    Logs().i(
      'StreamDialogBuilder::_listenClientLoginStateChanged - ${event.multipleAccountLoginType}',
    );
    if (event.multipleAccountLoginType ==
        MultipleAccountLoginType.firstLoggedIn) {
      _clientFirstLoggedIn = event.client;
      return;
    }

    if (event.multipleAccountLoginType ==
        MultipleAccountLoginType.otherAccountLoggedIn) {
      _clientAddAnotherAccount = event.client;
      return;
    }
  }

  void _handleFunctionOnDone() async {
    Logs().i('StreamDialogBuilder::_handleFunctionOnDone');
    Navigator.of(context, rootNavigator: false).pop();

    if (_clientFirstLoggedIn != null) {
      await _handleFirstLoggedIn(_clientFirstLoggedIn!);
      return;
    }

    if (_clientAddAnotherAccount != null) {
      _handleAddAnotherAccount(_clientAddAnotherAccount!);
      return;
    }
  }

  void _handleFunctionOnError(Object? error) {
    Logs().e('StreamDialogBuilder::_handleFunctionOnError - $error');
    Navigator.pop(context);
  }

  Future<void> _handleFirstLoggedIn(Client client) async {
    // Check for initial sharing intent before navigating
    final hasInitialSharingIntent = await _checkForInitialSharingIntent(client);

    // Only navigate to /rooms if there's no sharing intent
    // If there is a sharing intent, the matrix widget will handle navigation
    if (!hasInitialSharingIntent) {
      TwakeApp.router.go(
        '/rooms',
        extra: LoggedInBodyArgs(
          newActiveClient: client,
        ),
      );
    } else {
      Logs().i(
        'InitClientDialog::_handleFirstLoggedIn - Initial sharing intent detected, skipping navigation to /rooms',
      );
    }
  }

  /// Checks if there's an initial sharing intent (link or media) on first login.
  /// If found, initializes sharing intent immediately to process it.
  /// This prevents the navigation conflict where we'd navigate to /rooms
  /// before the sharing intent can navigate to the specific chat.
  ///
  /// Note: The stream listeners in matrix.dart remain as a fallback for:
  /// - Cases where no initial intent is detected here
  /// - Future sharing intents that come in while the app is running
  /// The _hasInitializedSharingIntent flag prevents duplicate setup.
  Future<bool> _checkForInitialSharingIntent(Client client) async {
    if (!PlatformInfos.isMobile) return false;

    try {
      // Check for initial link (deep link or shared link)
      // Note: This call consumes the buffered link, so we must process it
      final appLinks = AppLinks();
      final initialLink = await appLinks.getInitialLinkString();
      if (initialLink != null && initialLink.isNotEmpty) {
        Logs().d(
          'InitClientDialog::_checkForInitialSharingIntent - Found initial link: $initialLink',
        );
        // Initialize sharing intent immediately to set up stream listeners
        // and process the buffered link
        Matrix.of(context).initReceiveSharingIntent();
        return true;
      }

      // Check for initial shared media
      // Note: This call consumes the buffered media, so we must process it
      final initialMedia =
          await ReceiveSharingIntent.instance.getInitialMedia();
      if (initialMedia.isNotEmpty) {
        Logs().d(
          'InitClientDialog::_checkForInitialSharingIntent - Found initial media: ${initialMedia.length} files',
        );
        // Initialize sharing intent immediately to set up stream listeners
        // and process the buffered media
        Matrix.of(context).initReceiveSharingIntent();
        return true;
      }

      return false;
    } catch (e) {
      Logs().e(
        'InitClientDialog::_checkForInitialSharingIntent - Error: $e',
      );
      return false;
    }
  }

  void _handleAddAnotherAccount(Client client) {
    TwakeApp.router.go(
      '/rooms',
      extra: LoggedInOtherAccountBodyArgs(
        newActiveClient: client,
      ),
    );
  }

  void _initial() {
    loginSSOProgressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  void _startLoginSSOProgress() {
    loginSSOProgressController.addListener(() {
      setState(() {});
    });
    loginSSOProgressController.repeat();
  }

  @override
  void dispose() {
    loginSSOProgressController.dispose();
    _clientLoginStateChangedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        const WidthPlatformBreakpoint(
          end: ResponsiveUtils.maxMobileWidth,
        ): SlotLayout.from(
          key: breakpointMobileDialogKey,
          builder: (_) => TomBootstrapDialogMobileView(
            description: L10n.of(context)!.backingUpYourMessage,
          ),
        ),
        const WidthPlatformBreakpoint(
          begin: ResponsiveUtils.minTabletWidth,
        ): SlotLayout.from(
          key: breakpointWebAndDesktopDialogKey,
          builder: (_) => TomBootstrapDialogWebView(
            description: L10n.of(context)!.backingUpYourMessage,
          ),
        ),
      },
    );
  }
}
