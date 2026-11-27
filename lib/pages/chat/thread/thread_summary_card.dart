import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/thread/thread_resolved_mark.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_summary.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';

class ThreadSummaryCardStyle {
  static const int maxFaces = 3;
  static const double faceSize = 20;
  static const double ringWidth = 2;
  static const double ringedSize = faceSize + 2 * ringWidth;

  /// Distance between two faces: the rings overlap by 8 px.
  static const double faceStep = 16;
  static const double iconSize = 24;
  static const double unreadDotSize = LinagoraSpacing.base;

  /// The label is the body of a message (15) less 2 px, as the web.
  static const double labelSize = 13;
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: LinagoraSpacing.base * 1.5,
    vertical: LinagoraSpacing.base,
  );
}

/// The thread of a root, as ONE row at the very foot of its bubble, edge to
/// edge, a 1 px line above it: the faces of who replied, the thread icon and
/// « N comments ». The whole row is one button; the faces are decoration.
class ThreadSummaryCard extends StatelessWidget {
  const ThreadSummaryCard({
    super.key,
    required this.replyCount,
    this.repliers = const [],
    required this.onTap,
    this.unreadCount = 0,
    this.isResolved = false,
    this.onOwnBubble = false,
  });

  final int replyCount;

  /// Most recent first; the row shows the first three.
  final List<ThreadReplier> repliers;
  final int unreadCount;

  /// The thread was marked as resolved: the row carries a check.
  final bool isResolved;

  /// The row sits on a bubble of the user rather than a received one: the
  /// colour of the ring of the faces.
  final bool onOwnBubble;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final primary = LinagoraSysColors.material().primary;
    final count = l10n.threadCommentsCount(replyCount);
    final unread = unreadCount > 0;
    final faces = repliers.take(ThreadSummaryCardStyle.maxFaces).toList();

    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: [
        count,
        if (unread) l10n.threadUnreadMessagesCount(unreadCount),
        if (isResolved) l10n.threadResolved,
      ].join(', '),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outline)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: ThreadSummaryCardStyle.padding,
              child: Row(
                children: [
                  if (faces.isNotEmpty) ...[
                    _Faces(faces: faces, ring: _bubbleColor),
                    const SizedBox(width: LinagoraSpacing.base),
                  ],
                  Icon(
                    Icons.forum_outlined,
                    size: ThreadSummaryCardStyle.iconSize,
                    color: primary,
                  ),
                  const SizedBox(width: LinagoraSpacing.base * 0.5),
                  Flexible(
                    child: Text(
                      count,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LinagoraTextStyle.material().bodyMedium4.copyWith(
                        fontSize:
                            ThreadSummaryCardStyle.labelSize *
                            AppConfig.fontSizeFactor,
                        fontWeight: FontWeight.w500,
                        color: primary,
                      ),
                    ),
                  ),
                  if (unread)
                    Container(
                      width: ThreadSummaryCardStyle.unreadDotSize,
                      height: ThreadSummaryCardStyle.unreadDotSize,
                      margin: const EdgeInsetsDirectional.only(
                        start: LinagoraSpacing.base,
                      ),
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (isResolved) const ResolvedMark(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The colours [MessageBubble] of linagora_design_flutter paints.
  Color get _bubbleColor => onOwnBubble
      ? LinagoraRefColors.material().primary[95]!
      : LinagoraSysColors.material().onPrimary;
}

class _Faces extends StatelessWidget {
  const _Faces({required this.faces, required this.ring});

  final List<ThreadReplier> faces;
  final Color ring;

  @override
  Widget build(BuildContext context) => SizedBox(
    width:
        ThreadSummaryCardStyle.ringedSize +
        ThreadSummaryCardStyle.faceStep * (faces.length - 1),
    height: ThreadSummaryCardStyle.ringedSize,
    child: Stack(
      children: [
        for (final (i, face) in faces.indexed)
          PositionedDirectional(
            start: ThreadSummaryCardStyle.faceStep * i,
            child: Container(
              width: ThreadSummaryCardStyle.ringedSize,
              height: ThreadSummaryCardStyle.ringedSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: ring, shape: BoxShape.circle),
              child: Avatar(
                mxContent: face.avatarUrl,
                name: face.displayName ?? face.userId,
                size: ThreadSummaryCardStyle.faceSize,
                fontSize: 10,
              ),
            ),
          ),
      ],
    ),
  );
}
