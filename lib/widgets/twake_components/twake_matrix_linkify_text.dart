import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:linkfy_text/linkfy_text.dart';
import 'package:linkfy_text/src/utils/matrix_regex.dart';

class TwakeMatrixLinkifyText extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final TextStyle? linkStyle;
  final TextAlign? textAlign;
  final List<LinkType>? linkTypes;
  final ThemeData? themeData;
  final Function(Link)? onTapLink;
  final Function(TapDownDetails, Link)? onTapDownLink;
  final Function(TapDownDetails, Link)? onSecondaryTapDownLink;
  final int? maxLines;

  const TwakeMatrixLinkifyText({
    super.key,
    required this.text,
    this.textStyle,
    this.linkStyle,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.linkTypes,
    this.themeData,
    this.onTapLink,
    this.onTapDownLink,
    this.onSecondaryTapDownLink,
  });

  @override
  Widget build(BuildContext context) {
    return _TwakeCleanRichText(
      _twakeLinkifyTextSpans(
        text: text,
        textStyle: textStyle,
        linkStyle: linkStyle,
        linkTypes: linkTypes,
        themeData: themeData,
        onTapLink: onTapLink,
        onTapDownLink: onTapDownLink,
        onSecondaryTapDownLink: onSecondaryTapDownLink,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }
}

class _TwakeCleanRichText extends StatefulWidget {
  final InlineSpan child;
  final TextAlign? textAlign;
  final int? maxLines;

  const _TwakeCleanRichText(this.child, {this.textAlign, this.maxLines});

  @override
  State<_TwakeCleanRichText> createState() => _TwakeCleanRichTextState();
}

class _TwakeCleanRichTextState extends State<_TwakeCleanRichText> {
  void _disposeTextspan(TextSpan textSpan) {
    textSpan.recognizer?.dispose();
    if (textSpan.children != null) {
      for (final child in textSpan.children!) {
        if (child is TextSpan) {
          _disposeTextspan(child);
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.child is TextSpan) {
      _disposeTextspan(widget.child as TextSpan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      widget.child,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
    );
  }
}

class _TwakeLinkTextSpan extends TextSpan {
  final Link link;
  final void Function(TapDownDetails, Link)? onTapDownLink;
  final void Function(TapDownDetails, Link)? onSecondaryTapDownLink;
  final void Function(Link)? onTapLink;

  _TwakeLinkTextSpan({
    TextStyle? style,
    required this.link,
    String? text,
    this.onTapDownLink,
    this.onSecondaryTapDownLink,
    this.onTapLink,
    List<InlineSpan>? children,
  }) : super(
         style: style,
         text: text ?? '',
         children: children ?? <InlineSpan>[],
         recognizer: TapGestureRecognizer()
           ..onTap = () {
             if (onTapLink != null) {
               onTapLink(link);
             }
           }
           ..onTapDown = (details) {
             if (onTapDownLink != null) {
               onTapDownLink(details, link);
             }
           }
           ..onSecondaryTapDown = (details) {
             if (onSecondaryTapDownLink != null) {
               onSecondaryTapDownLink(details, link);
             }
           },
       ) {
    _fixRecognizer(this, recognizer!);
  }

  void _fixRecognizer(TextSpan textSpan, GestureRecognizer recognizer) {
    if (textSpan.children?.isEmpty ?? true) {
      return;
    }
    final fixedChildren = <InlineSpan>[];
    for (final child in textSpan.children!) {
      if (child is TextSpan && child.recognizer == null) {
        _fixRecognizer(child, recognizer);
        fixedChildren.add(
          TextSpan(
            text: child.text,
            style: child.style,
            recognizer: recognizer,
            children: child.children,
          ),
        );
      } else {
        fixedChildren.add(child);
      }
    }
    textSpan.children!.clear();
    textSpan.children!.addAll(fixedChildren);
  }
}

TextSpan _twakeLinkifyTextSpans({
  String text = '',
  TextStyle? linkStyle,
  TextStyle? textStyle,
  List<LinkType>? linkTypes,
  ThemeData? themeData,
  Function(Link)? onTapLink,
  Function(TapDownDetails, Link)? onTapDownLink,
  Function(TapDownDetails, Link)? onSecondaryTapDownLink,
}) {
  textStyle ??= themeData?.textTheme.bodyMedium;
  linkStyle ??= themeData?.textTheme.bodyMedium?.copyWith(
    color: themeData.colorScheme.secondary,
    decoration: TextDecoration.underline,
  );

  final regExp = constructMatrixRegExpFromLinkType(linkTypes ?? [LinkType.url]);

  if (!regExp.hasMatch(text) || text.isEmpty) {
    return TextSpan(
      text: text,
      style: textStyle,
      children: const [],
    );
  }

  final texts = text.split(regExp);
  final List<InlineSpan> spans = [];
  final highlights = regExp.allMatches(text).toList();

  for (final value in texts) {
    spans.add(
      TextSpan(
        text: value,
        style: textStyle,
        children: const [],
      ),
    );

    if (highlights.isNotEmpty) {
      final match = highlights.removeAt(0);
      final link = Link.fromTwakeMatch(match);
      if (link.type == null) {
        spans.add(
          TextSpan(
            text: link.value,
            style: textStyle,
            children: const [],
          ),
        );
        continue;
      }
      spans.add(
        _TwakeLinkTextSpan(
          text: link.value,
          link: link,
          style: linkStyle,
          onTapLink: onTapLink,
          onTapDownLink: onTapDownLink,
          onSecondaryTapDownLink: onSecondaryTapDownLink,
        ),
      );
    }
  }
  return TextSpan(children: spans);
}
