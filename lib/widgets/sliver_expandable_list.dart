import 'package:flutter/material.dart';

class SliverExpandableList extends StatefulWidget {
  final String title;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const SliverExpandableList({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  State<SliverExpandableList> createState() => _SliverExpandableListState();
}

class _SliverExpandableListState extends State<SliverExpandableList> {
  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: widget.itemCount,
      itemBuilder: widget.itemBuilder,
    );
  }
}
