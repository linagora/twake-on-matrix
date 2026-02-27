import 'package:fluffychat/pages/chat/chat_view_body_style.dart';
import 'package:flutter/material.dart';

class ChatBackground extends StatelessWidget {
  const ChatBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: ChatViewBodyStyle.backgroundColor),
          ),
          Positioned.fill(child: _BackgroundImage()),
        ],
      ),
    );
  }
}

class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(ChatViewBodyStyle.imageBackground),
          repeat: ImageRepeat.repeat,
          opacity: 0.1,
          alignment: Alignment.topLeft,
        ),
      ),
    );
  }
}
