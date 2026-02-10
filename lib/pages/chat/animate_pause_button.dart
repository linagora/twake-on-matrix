import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class AnimatedPauseButton extends StatefulWidget {
  const AnimatedPauseButton({super.key});

  @override
  State<AnimatedPauseButton> createState() => _AnimatedPauseButtonState();
}

class _AnimatedPauseButtonState extends State<AnimatedPauseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: LinagoraSysColors.material().surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: LinagoraSysColors.material().onPrimary,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: LinagoraSysColors.material().primary.withOpacity(
                      0.3 * _opacityAnimation.value,
                    ),
                    blurRadius: 8 * _opacityAnimation.value,
                    spreadRadius: 2 * _opacityAnimation.value,
                  ),
                ],
              ),
              child: Icon(
                Icons.pause,
                size: 20,
                color: LinagoraRefColors.material().neutral[50],
              ),
            ),
          ),
        );
      },
    );
  }
}
