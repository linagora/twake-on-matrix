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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadImage();
    });
  }

  @override
  void didUpdateWidget(covariant StreamImageViewer oldWidget) {
    if (oldWidget.matrixFile != widget.matrixFile) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadImage();
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    imageBytes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: imageBytes,
      builder: (_, bytes, __) {
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
