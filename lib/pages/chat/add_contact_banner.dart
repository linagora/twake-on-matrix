import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class AddContactBanner extends StatelessWidget {
  const AddContactBanner({super.key, required this.onTap, required this.show});

  final VoidCallback onTap;
  final ValueNotifier<bool> show;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: show,
      builder: (context, show, child) {
        if (!show) return const SizedBox();
        return child ?? const SizedBox();
      },
      child: Material(
        color: LinagoraSysColors.material().secondaryContainer,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_add_outlined,
                        color: LinagoraSysColors.material().primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        L10n.of(context)!.addToContacts,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 14,
                          height: 20 / 14,
                          color: LinagoraSysColors.material().primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: IconButton(
                      onPressed: show.toggle,
                      icon: Icon(
                        Icons.close,
                        color: LinagoraSysColors.material().primary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
