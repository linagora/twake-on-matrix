import 'package:twake_chat/generated/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie_native/lottie_native.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!context.mounted) return;

      context.pushReplacement('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 176,
            height: 176,
            child: LottieView.fromAsset(
              filePath: Assets.lottieChat.path,
              loop: false,
            ),
          ),
          Positioned(
            bottom: 40,
            child: SafeArea(
              child: Image.asset(Assets.branding.path, width: 210),
            ),
          ),
        ],
      ),
    );
  }
}
