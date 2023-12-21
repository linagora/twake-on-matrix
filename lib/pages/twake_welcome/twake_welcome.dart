import 'package:fluffychat/pages/twake_welcome/twake_welcome_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TwakeWelcome extends StatefulWidget {
  const TwakeWelcome({super.key});

  @override
  State<TwakeWelcome> createState() => TwakeWelcomeController();
}

class TwakeWelcomeController extends State<TwakeWelcome> {
  void goToLinagoraHomeserver() {
    context.push('/home/twakeid');
  }

  @override
  Widget build(BuildContext context) {
    return TwakeWelcomeView(
      controller: this,
    );
  }
}
