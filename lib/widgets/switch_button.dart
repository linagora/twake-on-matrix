import 'package:flutter/material.dart';

typedef OnSwitchButtonChanged = void Function(bool valueChanged);

class SwitchButton extends StatefulWidget {
  final OnSwitchButtonChanged onSwitchButtonChanged;

  final bool defaultSwitchValue;

  const SwitchButton({
    super.key,
    this.defaultSwitchValue = true,
    required this.onSwitchButtonChanged,
  });

  @override
  State<StatefulWidget> createState() => _SwitchButtonState();
}

class _SwitchButtonState extends State<SwitchButton> {
  late bool isOn = widget.defaultSwitchValue;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: isOn,
      onChanged: (value) {
        setState(() => isOn = value);
        widget.onSwitchButtonChanged(value);
      },
    );
  }
}
