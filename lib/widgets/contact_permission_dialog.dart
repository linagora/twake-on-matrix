import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactPermissionDialog extends StatefulWidget {

  final L10n l10n;

  const ContactPermissionDialog({
    Key? key,
    required this.l10n,
  }) : super(key: key);

  @override
  State<ContactPermissionDialog> createState() => _ContactPermissionDialogState();
}

class _ContactPermissionDialogState extends State<ContactPermissionDialog> 
  with WidgetsBindingObserver {

  Future<PermissionStatus> permissionContactRequest = Future.value(PermissionStatus.denied);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && !(await Permission.contacts.isDenied)) {
      Navigator.of(context).pop();
    }
  }

  @override
  dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.0),
          color: Theme.of(context).colorScheme.surface,
        ),
        width: 312,
        height: 280,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24.0,),
            const Icon(Icons.contacts_outlined),
            const SizedBox(height: 16.0,),
            Text(widget.l10n.permissionAccess,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface
              ),),
            const SizedBox(height: 16.0,),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  letterSpacing: 0.25,
                ),
                children: [
                  TextSpan(text: widget.l10n.permissionExplainsFirst),
                  TextSpan(text: widget.l10n.appName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold)),
                  TextSpan(text: widget.l10n.permissionExplainsTail),
                ]
              ),
            ),
            const SizedBox(height: 24.0),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildTextButton(
                    context: context,
                    text: "Deny",
                    onPressed: () async {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildTextButton(
                    context: context,
                    text: "Allow",
                    onPressed: () async {
                      permissionContactRequest = Permission.contacts.request();
                    }
                  )
                ],
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextButton({
    required String text,
    required VoidCallback? onPressed,
    required BuildContext context,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100.0),
        onTap: onPressed, 
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary
          ),),
        )),
    );
  }
}