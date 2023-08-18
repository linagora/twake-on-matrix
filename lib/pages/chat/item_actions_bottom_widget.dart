import 'package:fluffychat/pages/chat/chat_actions.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

typedef OnPickerTypeTap = void Function(PickerType);

class PickerTypeOnBottom extends StatelessWidget {
  final PickerType pickerType;
  final OnPickerTypeTap onPickerTypeTap;

  const PickerTypeOnBottom({
    super.key,
    required this.pickerType,
    required this.onPickerTypeTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onPickerTypeTap.call(pickerType),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: ShapeDecoration(
              color: pickerType.getBackgroundColor(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(36),
              ),
            ),
            child: Icon(
              pickerType.getIcon(),
              color: pickerType.getIconColor(),
            ),
          ),
          Text(
            pickerType.getTitle(context),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LinagoraSysColors.material().onBackground,
                ),
          ),
        ],
      ),
    );
  }
}
