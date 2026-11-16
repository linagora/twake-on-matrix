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

class AppLockScreenBackButton extends StatefulWidget {
  final Widget child;

  const AppLockScreenBackButton({super.key, required this.child});

  @override
  State<AppLockScreenBackButton> createState() =>
      _AppLockScreenBackButtonState();
}

// At launch the router is not built yet, so nothing else answers Back.
class _AppLockScreenBackButtonState extends State<AppLockScreenBackButton>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Future<bool> didPopRoute() async => true;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
