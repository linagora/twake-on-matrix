import 'dart:math';

import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/chat_loading_view_style.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:skeletons/skeletons.dart';

class ChatLoadingView extends StatelessWidget {
  const ChatLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = getIt.get<ResponsiveUtils>();
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
                    context: context,
                    responsive: responsive,
                    index: index,
                  ),
                  children: [
                    if (_shouldDisplayAvatar(
                      context: context,
                      responsive: responsive,
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
                      context: context,
                      responsive: responsive,
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
                    context: context,
                    responsive: responsive,
                    index: index,
                  ),
                  children: [
                    if (_shouldDisplayAvatar(
                      context: context,
                      responsive: responsive,
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
                      context: context,
                      responsive: responsive,
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
    required BuildContext context,
    required ResponsiveUtils responsive,
    required int index,
  }) {
    if (responsive.enableRightAndLeftMessageAlignment(context) == false) {
      return CrossAxisAlignment.end;
    }
    if (responsive.enableRightAndLeftMessageAlignment(context)) {
      return index % 2 == 0 ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    }

    return CrossAxisAlignment.end;
  }

  bool _shouldDisplayAvatar({
    required BuildContext context,
    required ResponsiveUtils responsive,
    required int index,
  }) {
    if (responsive.enableRightAndLeftMessageAlignment(context) == false) {
      return true;
    }
    if (responsive.enableRightAndLeftMessageAlignment(context)) {
      return index % 2 == 0 ? true : false;
    }

    return true;
  }

  int _random(int min, int max) {
    return min + Random().nextInt(max - min);
  }
}
