import 'package:flutter/widgets.dart';

class PinchDetector extends StatefulWidget {
  const PinchDetector({
    super.key,
    required this.onPinchChanged,
    required this.child,
  });

  final ValueChanged<bool> onPinchChanged;

  final Widget child;

  @override
  State<PinchDetector> createState() => _PinchDetectorState();
}

class _PinchDetectorState extends State<PinchDetector> {
  final Set<int> _activePointers = {};
  bool _pinching = false;

  void _onPointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);
    _updatePinching();
  }

  void _onPointerUp(PointerEvent event) {
    _activePointers.remove(event.pointer);
    _updatePinching();
  }

  void _updatePinching() {
    final pinching = _activePointers.length >= 2;
    if (pinching == _pinching) return;
    _pinching = pinching;
    widget.onPinchChanged(pinching);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: widget.child,
    );
  }
}
