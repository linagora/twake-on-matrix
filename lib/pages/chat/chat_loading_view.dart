import 'dart:math';

import 'package:fluffychat/pages/chat/chat_loading_view_style.dart';
import 'package:fluffychat/pages/chat/chat_view_body_style.dart';
import 'package:flutter/material.dart';
import 'package:skeletons/skeletons.dart';

class ChatLoadingView extends StatelessWidget {
  const ChatLoadingView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: ChatViewBodyStyle.chatScreenMaxWidth,
      ),
      alignment: Alignment.bottomCenter,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 20,
        itemBuilder: (context, index) {
          if (index < 3) {
            return Padding(
              padding: ChatLoadingViewStyle.padding(context),
              child: SkeletonItem(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SkeletonAvatar(
                      style: SkeletonAvatarStyle(
                        shape: BoxShape.circle,
                        width: 38,
                        height: 38,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SkeletonParagraph(
                        style: SkeletonParagraphStyle(
                          padding: EdgeInsets.zero,
                          lines: index + 1,
                          spacing: 8,
                          lineStyle: SkeletonLineStyle(
                            randomLength: true,
                            width: _random(
                              MediaQuery.sizeOf(context).width ~/ 2,
                              MediaQuery.sizeOf(context).width ~/ 0.25,
                            ).toDouble(),
                            height: _random(56, 96).toDouble(),
                            borderRadius: BorderRadius.circular(16),
                            minLength: MediaQuery.sizeOf(context).width / 4,
                            maxLength: MediaQuery.sizeOf(context).width / 0.25,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            );
          } else {
            return Padding(
              padding: ChatLoadingViewStyle.padding(context),
              child: SkeletonItem(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(
                      height: 46,
                      width: 46,
                    ),
                    Expanded(
                      child: SkeletonParagraph(
                        style: SkeletonParagraphStyle(
                          padding: EdgeInsets.zero,
                          lines: index + 1,
                          spacing: 8,
                          lineStyle: SkeletonLineStyle(
                            alignment: AlignmentDirectional.centerEnd,
                            randomLength: true,
                            width: _random(
                              MediaQuery.sizeOf(context).width ~/ 2,
                              MediaQuery.sizeOf(context).width ~/ 0.25,
                            ).toDouble(),
                            height: _random(56, 96).toDouble(),
                            borderRadius: BorderRadius.circular(16),
                            minLength: MediaQuery.sizeOf(context).width / 4,
                            maxLength: MediaQuery.sizeOf(context).width / 0.25,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  int _random(int min, int max) {
    return min + Random().nextInt(max - min);
  }
}
