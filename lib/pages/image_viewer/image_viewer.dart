import 'dart:typed_data';

import 'package:fluffychat/pages/forward/forward.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer_view.dart';
import 'package:fluffychat/presentation/model/pop_result_from_forward.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ImageViewer extends StatefulWidget {
  final Event? event;
  final Uint8List? imageData;
  final String? filePath;
  final VoidCallback? onCloseRightColumn;

  const ImageViewer({
    Key? key,
    this.event,
    this.imageData,
    this.filePath,
    this.onCloseRightColumn,
  }) : super(key: key);

  @override
  ImageViewerController createState() => ImageViewerController();
}

class ImageViewerController extends State<ImageViewer> {
  TransformationController transformationController =
      TransformationController();
  TapDownDetails? tapDownDetails;
  final double zoomScale = 3;

  static const String roomPathName = '/rooms/room';

  final ValueNotifier<bool> showAppbarPreview = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    transformationController.dispose();
    showAppbarPreview.dispose();
    super.dispose();
  }

  /// Forward this image to another room.
  void forwardAction() async {
    Matrix.of(context).shareContent = widget.event?.content;
    final result = await showDialog(
      context: context,
      useSafeArea: false,
      useRootNavigator: false,
      builder: (c) => const Forward(),
    );
    if (result is PopResultFromForward) {
      Navigator.of(context).pop<PopResultFromForward>();
    }
  }

  static const maxScaleFactor = 1.5;

  /// Go back if user swiped it away
  void onInteractionEnds(ScaleEndDetails endDetails) {
    if (PlatformInfos.usesTouchscreen == false) {
      if (endDetails.velocity.pixelsPerSecond.dy >
          MediaQuery.sizeOf(context).height * maxScaleFactor) {
        Navigator.of(context, rootNavigator: false).pop();
      }
    }
  }

  void onDoubleTap() {
    final position = tapDownDetails?.localPosition;
    if (position == null) return;

    final offset = Offset(
      position.dx * (1 - zoomScale),
      position.dy * (1 - zoomScale),
    );
    final zoomed = Matrix4.identity()
      ..translate(offset.dx, offset.dy)
      ..scale(zoomScale);

    final value = transformationController.value.isIdentity()
        ? zoomed
        : Matrix4.identity();
    transformationController.value = value;
  }

  void onDoubleTapDown(TapDownDetails details) {
    tapDownDetails = details;
  }

  @override
  Widget build(BuildContext context) => ImageViewerView(
        this,
        imageData: widget.imageData,
        filePath: widget.filePath,
      );
}
