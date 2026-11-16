import 'package:flutter/widgets.dart';

class AppLockBackButton extends StatefulWidget {
  final BackButtonDispatcher dispatcher;
  final Widget child;

  const AppLockBackButton({
    super.key,
    required this.dispatcher,
    required this.child,
  });

  @override
  State<AppLockBackButton> createState() => _AppLockBackButtonState();
}

class _AppLockBackButtonState extends State<AppLockBackButton> {
  ChildBackButtonDispatcher? _dispatcher;

  @override
  void initState() {
    super.initState();
    // The router below registers its own callback first; deferring needs it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _dispatcher = widget.dispatcher.createChildBackButtonDispatcher()
        ..addCallback(_onBack)
        ..takePriority();
    });
  }

  Future<bool> _onBack() => Navigator.of(context).maybePop();

  @override
  void dispose() {
    _dispatcher?.removeCallback(_onBack);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
