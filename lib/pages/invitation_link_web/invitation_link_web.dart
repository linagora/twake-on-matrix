import 'package:fluffychat/utils/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class InvitationLinkWeb extends StatefulWidget {
  final String? matrixId;

  const InvitationLinkWeb({super.key, this.matrixId});

  @override
  State<InvitationLinkWeb> createState() => _InvitationLinkWebState();
}

class _InvitationLinkWebState extends State<InvitationLinkWeb> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UrlLauncher(context, url: widget.matrixId).launchUrl();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CupertinoActivityIndicator(
          animating: true,
          color: LinagoraSysColors.material().onSurfaceVariant,
        ),
      ),
    );
  }
}
