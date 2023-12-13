import 'dart:math';

import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/pages/chat/input_bar/input_bar_style.dart';
import 'package:flutter/material.dart';

class FocusSuggestionList extends StatefulWidget {
  final Iterable<Widget> items;
  final ScrollController scrollController;
  final FocusSuggestionController focusSuggestionController;

  const FocusSuggestionList({
    super.key,
    required this.items,
    required this.scrollController,
    required this.focusSuggestionController,
  });

  @override
  State<FocusSuggestionList> createState() => _FocusSuggestionListState();
}

class _FocusSuggestionListState extends State<FocusSuggestionList> {
  static const _suggestionMaxVisible = 4.5;
  static const _scrollAnimationDuration = Duration(milliseconds: 300);

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
    final offset = (widget.focusSuggestionController.currentIndex.value - 2) *
        InputBarStyle.suggestionSize;
    widget.scrollController.animateTo(
      offset,
      duration: _scrollAnimationDuration,
      curve: Curves.linear,
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
        padding: EdgeInsets.symmetric(
          vertical: InputBarStyle.suggestionListPadding,
        ),
        itemCount: widget.items.length,
        itemBuilder: (context, index) => ValueListenableBuilder(
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
    );
  }
}
