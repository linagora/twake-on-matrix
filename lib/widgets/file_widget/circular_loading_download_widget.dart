import 'package:fluffychat/widgets/file_widget/message_file_tile_style.dart';
import 'package:flutter/material.dart';

class CircularLoadingDownloadWidget extends StatefulWidget {
  const CircularLoadingDownloadWidget({
    super.key,
    required this.downloadProgress,
    this.style = const MessageFileTileStyle(),
  });

  final double? downloadProgress;

  final MessageFileTileStyle style;

  @override
  State<CircularLoadingDownloadWidget> createState() =>
      _CircularLoadingDownloadWidgetState();
}

class _CircularLoadingDownloadWidgetState
    extends State<CircularLoadingDownloadWidget>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  static const animationDurationSeconds = 2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: animationDurationSeconds),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RotationTransition(
      turns: _animation!,
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.surface,
        strokeWidth: widget.style.strokeWidthLoading,
        value: widget.downloadProgress,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
