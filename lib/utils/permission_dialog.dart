import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:permission_handler/permission_handler.dart';

typedef OnAcceptButton = void Function()?;

class PermissionDialog extends StatefulWidget {
  final Permission permission;

  final Widget explainTextRequestPermission;

  final Widget? icon;

  final OnAcceptButton onAcceptButton;

  const PermissionDialog({
    Key? key,
    required this.permission,
    required this.explainTextRequestPermission,
    this.icon,
    this.onAcceptButton,
  }) : super(key: key);

  @override
  State<PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<PermissionDialog>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed &&
        !(await widget.permission.isDenied)) {
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
      child: Material(
        borderRadius: BorderRadius.circular(28.0),
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
              if (widget.icon != null) ...[
                const SizedBox(
                  height: 24.0,
                ),
                widget.icon!,
              ],
              const SizedBox(
                height: 16.0,
              ),
              widget.explainTextRequestPermission,
              const SizedBox(height: 24.0),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _PermissionTextButton(
                      context: context,
                      text: L10n.of(context)!.deny,
                      onPressed: () async {
                        Navigator.of(context).pop();
                      },
                    ),
                    _PermissionTextButton(
                      context: context,
                      text: L10n.of(context)!.allow,
                      onPressed: () async {
                        if (widget.onAcceptButton != null) {
                          widget.onAcceptButton!.call();
                        } else {
                          await widget.permission.request();
                        }
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTextButton extends StatelessWidget {
  const _PermissionTextButton({
    required this.text,
    required this.onPressed,
    required this.context,
  });

  final String text;
  final VoidCallback? onPressed;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100.0),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      ),
    );
  }
}
