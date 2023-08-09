import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

typedef OnAcceptButton = void Function()?;

class WarningDialogWidget extends StatefulWidget {
  final Widget explainTextRequestWidget;

  final OnAcceptButton onAcceptButton;

  const WarningDialogWidget({
    required this.explainTextRequestWidget,
    Key? key,
    this.onAcceptButton,
  }) : super(key: key);

  @override
  State<WarningDialogWidget> createState() => _WarningDialogWidgetState();
}

class _WarningDialogWidgetState extends State<WarningDialogWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  dispose() {
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
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24.0),
            widget.explainTextRequestWidget,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _WarningTextButton(
                    context: context,
                    text: L10n.of(context)!.continueProcess,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  _WarningTextButton(
                    context: context,
                    text: L10n.of(context)!.cancel,
                    onPressed: () async {
                      if (widget.onAcceptButton != null) {
                        widget.onAcceptButton!.call();
                      }
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningTextButton extends StatelessWidget {
  const _WarningTextButton({
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
