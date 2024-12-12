import 'package:fluffychat/pages/chat/chat_actions.dart';
import 'package:flutter/material.dart';

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
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(36),
              ),
            ),
            child: Icon(
              size: 24,
              pickerType.getIcon(),
              color: pickerType.getIconColor(),
            ),
          ),
          Text(
            pickerType.getTitle(context),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: pickerType.getTextColor(context),
                ),
          ),
        ],
      ),
    );
  }
}
