import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:flutter/material.dart';
import 'dart:async';

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
  final ValueNotifier<MatrixFile?> imageBytes = ValueNotifier(null);

  Future<void> _loadImage() async {
    final convertMatrix = await widget.matrixFile.convertReadStreamToBytes();
    widget.onImageLoaded.call(convertMatrix);
    imageBytes.value = convertMatrix;
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant StreamImageViewer oldWidget) {
    if (oldWidget.matrixFile != widget.matrixFile) {
      _loadImage();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: imageBytes,
      builder: (context, bytes, _) {
        if (bytes == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return InteractiveViewer(
          minScale: 0.1,
          maxScale: 5.0,
          child: Image.memory(
            bytes.bytes!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        );
      },
    );
  }
}
