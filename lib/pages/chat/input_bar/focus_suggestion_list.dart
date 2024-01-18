import 'dart:math';

import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/pages/chat/input_bar/input_bar_style.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class FocusSuggestionList extends StatefulWidget {
  final Iterable<Widget> items;
  final AutoScrollController? scrollController;
  final FocusSuggestionController focusSuggestionController;

  const FocusSuggestionList({
    super.key,
    required this.items,
    this.scrollController,
    required this.focusSuggestionController,
  });

  @override
  State<FocusSuggestionList> createState() => _FocusSuggestionListState();
}

class _FocusSuggestionListState extends State<FocusSuggestionList> {
  static const _suggestionMaxVisible = 4.5;
  static const _scrollAnimationDuration = Duration(milliseconds: 10);

  @override
  void initState() {
    widget.focusSuggestionController.currentIndex
        .addListener(_suggestionIndexChanged);
    super.initState();
  }

  @override
  void dispose() {
    widget.focusSuggestionController.currentIndex
        .removeListener(_suggestionIndexChanged);
    super.dispose();
  }

  void _suggestionIndexChanged() {
    widget.scrollController?.scrollToIndex(
      widget.focusSuggestionController.currentIndex.value,
      preferPosition: AutoScrollPosition.middle,
      duration: _scrollAnimationDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final listHeight = InputBarStyle.suggestionSize *
            min(_suggestionMaxVisible, widget.items.length) +
        InputBarStyle.suggestionListPadding * 2;
    return SizedBox(
      height: listHeight,
      child: ListView.builder(
        controller: widget.scrollController,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          vertical: InputBarStyle.suggestionListPadding,
        ),
        itemCount: widget.items.length,
        itemBuilder: (context, index) => AutoScrollTag(
          key: ValueKey(index),
          index: index,
          highlightColor: ThemeData().hoverColor,
          controller: widget.scrollController ?? AutoScrollController(),
          child: ValueListenableBuilder(
            valueListenable: widget.focusSuggestionController.currentIndex,
            builder: (context, currentIndex, child) {
              return Container(
                color: currentIndex == index ? ThemeData().hoverColor : null,
                child: child,
              );
            },
            child: widget.items.elementAt(index),
          ),
        ),
      ),
    );
  }
}
