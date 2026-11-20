import 'package:flutter/widgets.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:twake_chat/widgets/lock_screen.dart';

class TwakeAppLock extends StatelessWidget {
  final BackButtonDispatcher dispatcher;
  final bool initiallyEnabled;
  final Widget child;

  const TwakeAppLock({
    super.key,
    required this.dispatcher,
    required this.initiallyEnabled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => AppLock(
    builder: (_, _) => _AppLockBackButton(dispatcher: dispatcher, child: child),
    lockScreenBuilder: (_) =>
        const _AppLockScreenBackButton(child: LockScreen()),
    initiallyEnabled: initiallyEnabled,
    initialBackgroundLockLatency: Duration.zero,
  );
}

class _AppLockBackButton extends StatefulWidget {
  final BackButtonDispatcher dispatcher;
  final Widget child;

  const _AppLockBackButton({required this.dispatcher, required this.child});

  @override
  State<_AppLockBackButton> createState() => _AppLockBackButtonState();
}

class _AppLockBackButtonState extends State<_AppLockBackButton> {
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

class _AppLockScreenBackButton extends StatefulWidget {
  final Widget child;

  const _AppLockScreenBackButton({required this.child});

  @override
  State<_AppLockScreenBackButton> createState() =>
      _AppLockScreenBackButtonState();
}

// At launch the router is not built yet, so nothing else answers Back.
class _AppLockScreenBackButtonState extends State<_AppLockScreenBackButton>
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
