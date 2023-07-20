import 'package:fluffychat/widgets/switch_button.dart';
import 'package:flutter/material.dart';

class SettingTile extends StatelessWidget {
  final IconData leadingIcon;

  final String settingTitle;

  final String? settingDescription;

  final OnSwitchButtonChanged onSwitchButtonChanged;

  final bool defaultSwitchValue;

  final bool isEditable;

  const SettingTile({
    super.key,
    required this.leadingIcon,
    required this.settingTitle,
    required this.onSwitchButtonChanged,
    this.settingDescription,
    this.defaultSwitchValue = true,
    this.isEditable = true,
  });

  static const opacityForDisable = 0.6;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, right: 4.0),
      child: Opacity(
        opacity: isEditable ? 1 : opacityForDisable,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Icon(
                leadingIcon,
              ),
            ),
            const SizedBox(
              width: 8.0,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      settingTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            letterSpacing: 0.15,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  if (settingDescription != null &&
                      settingDescription!.isNotEmpty)
                    Text(
                      settingDescription!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            letterSpacing: 0.4,
                          ),
                    ),
                ],
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            IgnorePointer(
              ignoring: !isEditable,
              child: SwitchButton(
                defaultSwitchValue: defaultSwitchValue,
                onSwitchButtonChanged: (value) => onSwitchButtonChanged(value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
