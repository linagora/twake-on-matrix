import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

class StreamImageViewer extends StatefulWidget {
  final MatrixFile matrixFile;
  final Function(MatrixFile) onImageLoaded;

  const StreamImageViewer({
    super.key,
    required this.matrixFile,
    required this.onImageLoaded,
  });

  @override
  StreamImageViewerState createState() => StreamImageViewerState();
}

class StreamImageViewerState extends State<StreamImageViewer> {
  MatrixFile? imageFile;

  void _loadImage() {
    widget.onImageLoaded.call(widget.matrixFile);
    imageFile = widget.matrixFile;
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant StreamImageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matrixFile != widget.matrixFile) {
      _loadImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (imageFile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return InteractiveViewer(
      minScale: 0.1,
      maxScale: 5.0,
      child: Image.memory(
        imageFile!.bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const SizedBox(),
      ),
    );
  }
}
