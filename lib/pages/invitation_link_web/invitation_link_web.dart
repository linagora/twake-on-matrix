import 'package:fluffychat/utils/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      final matrixId = widget.matrixId;
      if (matrixId == null || matrixId.isEmpty) {
        context.go('/rooms');
        return;
      }
      UrlLauncher(context, url: widget.matrixId).launchUrl();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CupertinoActivityIndicator(
          color: LinagoraSysColors.material().onSurfaceVariant,
        ),
      ),
    );
  }
}
