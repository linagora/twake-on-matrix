import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

typedef OnAcceptButton = void Function()?;
typedef OnRefuseTap = void Function()?;

class PermissionDialog extends StatefulWidget {
  final Permission permission;

  final Widget explainTextRequestPermission;

  final Widget? icon;

  final OnAcceptButton onAcceptButton;

  final OnRefuseTap onRefuseTap;

  const PermissionDialog({
    super.key,
    required this.permission,
    required this.explainTextRequestPermission,
    this.icon,
    this.onAcceptButton,
    this.onRefuseTap,
  });

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
  void dispose() {
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
          width: MediaQuery.sizeOf(context).width * 0.85,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: IntrinsicHeight(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!PlatformInfos.isIOS)
                      _PermissionTextButton(
                        context: context,
                        text: L10n.of(context)!.deny,
                        onPressed: () {
                          widget.onRefuseTap?.call();
                          Navigator.of(context).pop();
                        },
                      ),
                    _PermissionTextButton(
                      context: context,
                      text: L10n.of(context)!.next,
                      onPressed: () async {
                        if (widget.onAcceptButton != null) {
                          widget.onAcceptButton!.call();
                        } else {
                          await widget.permission.request().then(
                                (value) => Navigator.of(context).pop(),
                              );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
              ],
            ),
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
