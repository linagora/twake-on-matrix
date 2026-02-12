import 'package:async/async.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';

class TypingTimerWrapper extends StatefulWidget {
  const TypingTimerWrapper({
    super.key,
    required this.room,
    required this.l10n,
    required this.typingWidget,
    this.notTypingWidget = const SizedBox(),
  });

  final Room room;
  final L10n l10n;
  final Widget typingWidget;
  final Widget notTypingWidget;

  @override
  State<TypingTimerWrapper> createState() => _TypingTimerWrapperState();
}

class _TypingTimerWrapperState extends State<TypingTimerWrapper> {
  bool showTyping = false;
  late RestartableTimer timer;

  void checkTyping() {
    if (!mounted) return;

    if (widget.room.typingUsers.isEmpty) {
      showTyping = false;
      timer.cancel();
      return;
    }

    if (widget.room.getLocalizedTypingText(widget.l10n).isNotEmpty) {
      showTyping = true;
      timer.reset();
    }
  }

  @override
  void initState() {
    super.initState();
    timer = RestartableTimer(const Duration(seconds: 30), () {
      if (!mounted) return;

      setState(() {
        showTyping = false;
      });
    })..cancel();
    checkTyping();
  }

  @override
  void didUpdateWidget(covariant TypingTimerWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    checkTyping();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (showTyping) return widget.typingWidget;

    return widget.notTypingWidget;
  }
}
