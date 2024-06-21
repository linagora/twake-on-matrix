import 'dart:async';
import 'dart:typed_data';

import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/download/download_file_state.dart';
import 'package:fluffychat/domain/usecase/room/download_media_file_interactor.dart';
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
  final double? width;
  final double? height;

  const ImageViewer({
    super.key,
    this.event,
    this.imageData,
    this.filePath,
    this.width,
    this.height,
  });

  @override
  ImageViewerController createState() => ImageViewerController();
}

class ImageViewerController extends State<ImageViewer> {
  TransformationController transformationController =
      TransformationController();
  TapDownDetails? tapDownDetails;
  final double zoomScale = 3;

  final ValueNotifier<bool> showAppbarPreview = ValueNotifier(true);

  String? filePath;

  String? thumbnailFilePath;

  final downloadMediaFileInteractor = getIt.get<DownloadMediaFileInteractor>();

  StreamSubscription? streamSubcription;

  @override
  void initState() {
    super.initState();
    if (!PlatformInfos.isWeb && widget.event != null) {
      handleDownloadFile(widget.event!);
      handleDownloadThumbnailFile(widget.event!);
    }
  }

  Future<void> handleDownloadFile(Event event) async {
    try {
      streamSubcription =
          downloadMediaFileInteractor.execute(event: event).listen((state) {
        state.fold(
          (failure) {
            if (failure is DownloadMediaFileFailure) {
              Logs().e('Error downloading file', failure.exception);
            }
          },
          (success) {
            if (success is DownloadMediaFileSuccess) {
              setState(() {
                filePath = success.filePath;
              });
            }
          },
        );
      });
    } catch (e) {
      Logs().e('Error downloading file', e);
    }
  }

  Future<void> handleDownloadThumbnailFile(Event event) async {
    try {
      streamSubcription = downloadMediaFileInteractor
          .execute(event: event, getThumbnail: true)
          .listen((state) {
        state.fold(
          (failure) {
            if (failure is DownloadMediaFileFailure) {
              Logs().e('Error downloading file', failure.exception);
            }
          },
          (success) {
            if (success is DownloadMediaFileSuccess) {
              setState(() {
                thumbnailFilePath = success.filePath;
              });
            }
          },
        );
      });
    } catch (e) {
      Logs().e('Error downloading file', e);
    }
  }

  @override
  void dispose() {
    streamSubcription?.cancel();
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
        width: widget.width,
        height: widget.height,
      );
}
