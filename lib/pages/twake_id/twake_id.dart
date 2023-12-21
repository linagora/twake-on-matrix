import 'package:fluffychat/pages/twake_id/twake_id_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TwakeId extends StatefulWidget {
  const TwakeId({super.key});

  @override
  State<TwakeId> createState() => TwakeIdController();
}

class TwakeIdController extends State<TwakeId> {
  void goToHomeserverPicker() {
    context.push('/home/homeserverpicker');
  }

  @override
  Widget build(BuildContext context) {
    return TwakeIdView(controller: this);
  }
}
