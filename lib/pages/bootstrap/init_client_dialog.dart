import 'dart:async';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog_mobile_view.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog_web_view.dart';
import 'package:fluffychat/presentation/model/client_login_state_event.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/agruments/logged_in_body_args.dart';
import 'package:fluffychat/widgets/layouts/agruments/logged_in_other_account_body_args.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:matrix/matrix.dart';
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
      _handleFirstLoggedIn(event.client);
      return;
    }

    if (event.multipleAccountLoginType ==
        MultipleAccountLoginType.otherAccountLoggedIn) {
      _handleAddAnotherAccount(event.client);
      return;
    }
  }

  void _handleFunctionOnDone() async {
    Logs().i('StreamDialogBuilder::_handleFunctionOnDone');
  }

  void _handleFunctionOnError(Object? error) {
    Logs().e('StreamDialogBuilder::_handleFunctionOnError - $error');
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _handleFirstLoggedIn(Client client) {
    Navigator.of(context, rootNavigator: false).pop();

    TwakeApp.router.go(
      '/rooms',
      extra: LoggedInBodyArgs(
        newActiveClient: client,
      ),
    );
  }

  void _handleAddAnotherAccount(Client client) {
    Navigator.of(context, rootNavigator: false).pop();

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
