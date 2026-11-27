import 'dart:math';

import 'package:twake_chat/pages/chat/chat_loading_view_style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/providers/personalization/display_preferences_controller.dart';
import 'package:flutter/material.dart';
import 'package:skeletons/skeletons.dart';

class ChatLoadingView extends ConsumerWidget {
  const ChatLoadingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alignOwnRight = ref.watch(alignOwnMessagesRightProvider);
    return Container(
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
                  crossAxisAlignment: _crossAxisAlignment(
                    alignOwnRight: alignOwnRight,
                    index: index,
                  ),
                  children: [
                    if (_shouldDisplayAvatar(
                      alignOwnRight: alignOwnRight,
                      index: index,
                    ))
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
                    if (!_shouldDisplayAvatar(
                      alignOwnRight: alignOwnRight,
                      index: index,
                    )) ...[
                      const SizedBox(width: 8),
                      const SkeletonAvatar(
                        style: SkeletonAvatarStyle(
                          shape: BoxShape.circle,
                          width: 38,
                          height: 38,
                        ),
                      ),
                    ] else
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
                  crossAxisAlignment: _crossAxisAlignment(
                    alignOwnRight: alignOwnRight,
                    index: index,
                  ),
                  children: [
                    if (_shouldDisplayAvatar(
                      alignOwnRight: alignOwnRight,
                      index: index,
                    )) ...[
                      const SkeletonAvatar(
                        style: SkeletonAvatarStyle(
                          shape: BoxShape.circle,
                          width: 38,
                          height: 38,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
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
                    if (!_shouldDisplayAvatar(
                      alignOwnRight: alignOwnRight,
                      index: index,
                    )) ...[
                      const SizedBox(width: 8),
                      const SkeletonAvatar(
                        style: SkeletonAvatarStyle(
                          shape: BoxShape.circle,
                          width: 38,
                          height: 38,
                        ),
                      ),
                    ] else
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

  CrossAxisAlignment _crossAxisAlignment({
    required bool alignOwnRight,
    required int index,
  }) => alignOwnRight && index.isOdd
      ? CrossAxisAlignment.start
      : CrossAxisAlignment.end;

  bool _shouldDisplayAvatar({
    required bool alignOwnRight,
    required int index,
  }) => !alignOwnRight || index.isEven;

  int _random(int min, int max) {
    return min + Random().nextInt(max - min);
  }
}
