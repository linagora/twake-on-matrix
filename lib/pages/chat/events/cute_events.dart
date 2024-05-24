import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/app_config.dart';

class CuteContent extends StatefulWidget {
  final Event event;

  const CuteContent(this.event, {super.key});

  @override
  State<CuteContent> createState() => _CuteContentState();
}

class _CuteContentState extends State<CuteContent> {
  static bool _isOverlayShown = false;

  @override
  void initState() {
    if (AppConfig.autoplayImages && !_isOverlayShown) {
      addOverlay();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: widget.event.fetchSenderUser(),
      builder: (context, snapshot) {
        final label = generateLabel(snapshot.data);

        return GestureDetector(
          onTap: addOverlay,
          child: SizedBox.square(
            dimension: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.event.text,
                  style: const TextStyle(fontSize: 150),
                ),
                if (label != null) Text(label),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> addOverlay() async {
    _isOverlayShown = true;
    await Future.delayed(const Duration(milliseconds: 50));

    OverlayEntry? overlay;
    overlay = OverlayEntry(
      builder: (context) => CuteEventOverlay(
        emoji: widget.event.text,
        onAnimationEnd: () {
          _isOverlayShown = false;
          overlay?.remove();
        },
      ),
    );
    Overlay.of(context).insert(overlay);
  }

  String? generateLabel(User? user) {
    switch (widget.event.content['cute_type']) {
      case 'googly_eyes':
        return L10n.of(context)?.googlyEyesContent(
          user?.displayName ??
              widget.event.senderFromMemoryOrFallback.displayName ??
              '',
        );
      case 'cuddle':
        return L10n.of(context)?.cuddleContent(
          user?.displayName ??
              widget.event.senderFromMemoryOrFallback.displayName ??
              '',
        );
      case 'hug':
        return L10n.of(context)?.hugContent(
          user?.displayName ??
              widget.event.senderFromMemoryOrFallback.displayName ??
              '',
        );
      default:
        return null;
    }
  }
}

class CuteEventOverlay extends StatefulWidget {
  final String emoji;
  final VoidCallback onAnimationEnd;

  const CuteEventOverlay({
    super.key,
    required this.emoji,
    required this.onAnimationEnd,
  });

  @override
  State<CuteEventOverlay> createState() => _CuteEventOverlayState();
}

class _CuteEventOverlayState extends State<CuteEventOverlay>
    with TickerProviderStateMixin {
  final List<Size> items = List.generate(
    50,
    (index) => Size(
      Random().nextDouble(),
      4 + (Random().nextDouble() * 4),
    ),
  );

  AnimationController? controller;

  @override
  void initState() {
    controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    controller?.forward();
    controller?.addStatusListener(_hideOverlay);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller!,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth - CuteOverlayContent.size;
          final height = constraints.maxHeight + CuteOverlayContent.size;
          return SizedBox(
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            child: Stack(
              alignment: Alignment.bottomLeft,
              fit: StackFit.expand,
              children: items
                  .map(
                    (position) => Positioned(
                      left: position.width * width,
                      bottom: (height *
                              .25 *
                              position.height *
                              (controller?.value ?? 0)) -
                          CuteOverlayContent.size,
                      child: CuteOverlayContent(
                        emoji: widget.emoji,
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  void _hideOverlay(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onAnimationEnd.call();
    }
  }
}

class CuteOverlayContent extends StatelessWidget {
  static const double size = 64.0;
  final String emoji;

  const CuteOverlayContent({super.key, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 48),
      ),
    );
  }
}
