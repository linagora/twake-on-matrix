import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/download/download_file_state.dart';
import 'package:fluffychat/domain/usecase/room/download_media_file_interactor.dart';
import 'package:fluffychat/pages/forward/forward.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer_view.dart';
import 'package:fluffychat/widgets/media_viewer_web_overlay.dart';
import 'package:fluffychat/presentation/model/pop_result_from_forward.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer_style.dart';
import 'package:fluffychat/utils/image_zoom_scope.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
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
  final bool showAppBar;
  final void Function(bool isZoomed)? onZoomChanged;

  const ImageViewer({
    super.key,
    this.event,
    this.imageData,
    this.filePath,
    this.width,
    this.height,
    this.showAppBar = true,
    this.onZoomChanged,
  });

  @override
  ImageViewerController createState() => ImageViewerController();
}

class ImageViewerController extends State<ImageViewer> {
  TransformationController transformationController =
      TransformationController();
  TapDownDetails? tapDownDetails;
  final double zoomScale = 3;

  bool _isZoomed = false;
  ValueNotifier<bool>? _zoomScopeNotifier;

  late final ValueNotifier<bool> showAppbarPreview;

  Uint8List? bytes;

  Uint8List? thumbnailBytes;

  final downloadMediaFileInteractor = getIt.get<DownloadMediaFileInteractor>();

  StreamSubscription? streamSubcription;

  final _webOverlay = MediaViewerWebOverlay.image();

  @override
  void initState() {
    super.initState();
    showAppbarPreview = ValueNotifier(widget.showAppBar);
    transformationController.addListener(_handleZoomChanged);
    if (PlatformInfos.isWeb && widget.event != null) {
      _injectWebImageOverlay(widget.event!);
    }
    if (!PlatformInfos.isWeb && widget.event != null) {
      handleDownloadFile(widget.event!);
      handleDownloadThumbnailFile(widget.event!);
    }
  }

  /// Downloads the image bytes and injects a transparent `<img>` overlay into
  /// the DOM so the browser's native "Save Image As" context menu works.
  Future<void> _injectWebImageOverlay(Event event) async {
    try {
      final matrixFile = await event.downloadAndDecryptAttachment();
      if (!mounted) return;
      final mimeType = event.mimeType ?? 'image/jpeg';
      _webOverlay.attach(
        bytes: matrixFile.bytes,
        mimeType: mimeType,
        appBarHeight: ImageViewerStyle.appBarHeight ?? 56,
      );
    } catch (e) {
      Logs().e('ImageViewerController: failed to inject web overlay', e);
    }
  }

  Future<void> handleDownloadFile(Event event) async {
    try {
      streamSubcription = downloadMediaFileInteractor
          .execute(event: event)
          .listen((state) {
            state.fold(
              (failure) {
                if (failure is DownloadMediaFileFailure) {
                  Logs().e('Error downloading file', failure.exception);
                }
              },
              (success) {
                if (success is DownloadMediaFileSuccess) {
                  if (success.fileInfo.bytes != null) {
                    setState(() {
                      bytes = success.fileInfo.bytes!;
                    });
                  } else if (success.fileInfo.filePath != null) {
                    File(success.fileInfo.filePath!).readAsBytes().then((data) {
                      if (mounted) {
                        setState(() {
                          bytes = data;
                        });
                      }
                    });
                  }
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
                  if (success.fileInfo.bytes != null) {
                    setState(() {
                      thumbnailBytes = success.fileInfo.bytes!;
                    });
                  } else if (success.fileInfo.filePath != null) {
                    File(success.fileInfo.filePath!).readAsBytes().then((data) {
                      if (mounted) {
                        setState(() {
                          thumbnailBytes = data;
                        });
                      }
                    });
                  }
                }
              },
            );
          });
    } catch (e) {
      Logs().e('Error downloading file', e);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _zoomScopeNotifier = ImageZoomScope.maybeOf(context);
  }

  @override
  void dispose() {
    _webOverlay.dispose();
    streamSubcription?.cancel();
    transformationController.removeListener(_handleZoomChanged);
    transformationController.dispose();
    showAppbarPreview.dispose();
    super.dispose();
  }

  void _handleZoomChanged() {
    final isZoomed =
        transformationController.value.getMaxScaleOnAxis() >
        ImageViewerStyle.minScaleInteractiveViewer;
    if (isZoomed == _isZoomed) return;
    _isZoomed = isZoomed;
    widget.onZoomChanged?.call(isZoomed);
    _zoomScopeNotifier?.value = isZoomed;
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
    if (_isZoomed) return;
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
