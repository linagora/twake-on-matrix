import 'package:flutter/material.dart';

typedef OnAcceptButton = void Function()?;

class WarningDialogWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final List<DialogAction>? actions;

  const WarningDialogWidget({
    super.key,
    this.title,
    this.message,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.0),
          color: Theme.of(context).colorScheme.surface,
        ),
        width: 312,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  message!,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: (actions ?? [])
                  .map((action) => _WarningTextButton(action: action))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class DialogAction {
  final String text;
  final Color? textColor;
  final VoidCallback? onPressed;

  DialogAction({
    required this.text,
    this.onPressed,
    this.textColor,
  });
}

class _WarningTextButton extends StatelessWidget {
  final DialogAction action;

  const _WarningTextButton({
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100.0),
        onTap: action.onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Text(
            action.text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color:
                      action.textColor ?? Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      ),
    );
  }
}
