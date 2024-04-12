import 'dart:async';
import 'package:fluffychat/presentation/model/client_login_state_event.dart';
import 'package:fluffychat/widgets/layouts/agruments/logged_in_body_args.dart';
import 'package:fluffychat/widgets/layouts/agruments/logged_in_other_account_body_args.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

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
      _handleFirstLoggedIn(_clientFirstLoggedIn!);
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

  void _handleFirstLoggedIn(Client client) {
    TwakeApp.router.go(
      '/rooms',
      extra: LoggedInBodyArgs(
        newActiveClient: client,
      ),
    );
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
    return const Scaffold(
      backgroundColor: Colors.transparent,
    );
  }
}
