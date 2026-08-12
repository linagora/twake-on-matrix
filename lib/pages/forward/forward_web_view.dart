import 'package:twake_chat/pages/forward/forward.dart';
import 'package:twake_chat/pages/forward/forward_web_view_style.dart';
import 'package:flutter/material.dart';

class ForwardWebView extends StatelessWidget {
  const ForwardWebView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: ForwardWebViewStyle.dialogWidth,
        height: ForwardWebViewStyle.dialogHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(ForwardWebViewStyle.dialogBorderRadius),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: const Forward(isFullScreen: false),
      ),
    );
  }
}
