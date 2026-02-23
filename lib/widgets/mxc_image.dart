import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer.dart';
import 'package:fluffychat/pages/media_viewer/media_viewer.dart';
import 'package:fluffychat/presentation/enum/chat/media_viewer_popup_result_enum.dart';
import 'package:fluffychat/presentation/extensions/send_file_web_extension.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/utils/interactive_viewer_gallery.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/hero_page_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/widgets/matrix.dart';

typedef EventId = String;
typedef ImageData = Uint8List;

class MxcImage extends StatefulWidget {
  final Uri? uri;
  final Event? event;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool isThumbnail;
  final bool animated;
  final Duration animationDuration;
  final Widget Function(BuildContext context)? placeholder;
  final bool rounded;
  final void Function()? onTapPreview;
  final void Function()? onTapSelectMode;
  final bool isPreview;
  final bool enableHeroAnimation;

  /// Enable it if the image is stretched, and you don't want to resize it
  final bool noResize;

  final VoidCallback? closeRightColumn;

  final int? cacheWidth;

  final int? cacheHeight;

  final bool keepAlive;

  const MxcImage({
    this.uri,
    this.event,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.isThumbnail = true,
    this.animated = false,
    this.animationDuration = const Duration(milliseconds: 500),
    this.rounded = false,
    this.onTapPreview,
    this.onTapSelectMode,
    this.isPreview = false,
    this.noResize = false,
    this.closeRightColumn,
    this.cacheWidth,
    this.cacheHeight,
    this.enableHeroAnimation = true,
    this.keepAlive = false,
    super.key,
  });

  @override
  State<MxcImage> createState() => _MxcImageState();
}

class _MxcImageState extends State<MxcImage>
    with AutomaticKeepAliveClientMixin {
  static const String placeholderKey = 'placeholder';
  ImageData? _imageData;
  bool isLoadDone = false;
  String? filePath;

  Future<({Uint8List? imageData, String? filePath})> _loadEvent(
    BuildContext context,
  ) async {
    if (!context.mounted) return (imageData: null, filePath: null);
    final event = widget.event;
    if (event == null) return (imageData: null, filePath: null);

    try {
      if (!PlatformInfos.isWeb) {
        final fileInfo = await event.getFileInfo(
          getThumbnail: widget.isThumbnail,
        );
        Logs().d('MxcImage::Downloaded get file info = $fileInfo');
        if (fileInfo != null) {
          return (imageData: fileInfo.bytes, filePath: fileInfo.filePath);
        }
      }

      final matrixFile = await event.downloadAndDecryptAttachment(
        getThumbnail: widget.isThumbnail,
      );
      Logs().d(
        'MxcImage::Downloaded attachment name = ${matrixFile.name} - mimeType = ${matrixFile.mimeType} - bytes = ${matrixFile.bytes.length}',
      );
      if (_notImageOrVideo(matrixFile, event)) {
        return (imageData: null, filePath: null);
      }
      return (imageData: matrixFile.bytes, filePath: null);
    } catch (e) {
      Logs().e('MxcImage::Error while downloading image: $e');
      rethrow;
    }
  }

  bool _notImageOrVideo(MatrixFile matrixFile, Event event) =>
      !matrixFile.isImage() && !event.isVideoOrImage;

  Future<void> _tryLoadEvent(BuildContext context) async {
    try {
      final loadResult = await _loadEvent(context);
      isLoadDone = true;
      _imageData = loadResult.imageData;
      filePath = loadResult.filePath;
      setState(() {});
    } catch (e) {
      if (mounted && !isLoadDone) {
        isLoadDone = true;
        _tryLoadEvent(context);
      }
    }
  }

  void _onTap(BuildContext context) async {
    if (widget.onTapPreview != null) {
      widget.onTapPreview!();
      final result =
          await Navigator.of(context, rootNavigator: PlatformInfos.isWeb).push(
            HeroPageRoute(
              builder: (context) {
                return InteractiveViewerGallery(
                  itemBuilder: PlatformInfos.isMobile
                      ? MediaViewer(event: widget.event!)
                      : ImageViewer(event: widget.event!),
                );
              },
            ),
          );
      if (result == MediaViewerPopupResultEnum.closeRightColumnFlag) {
        widget.closeRightColumn?.call();
      }
    } else if (widget.onTapSelectMode != null) {
      widget.onTapSelectMode!();
      return;
    } else {
      return;
    }
  }

  Widget placeholder(BuildContext context) =>
      widget.placeholder?.call(context) ??
      const Center(
        key: Key(placeholderKey),
        child: CupertinoActivityIndicator(),
      );

  @override
  void initState() {
    super.initState();
    // URI-based images are handled by CachedNetworkImage directly.
    // Only run the download flow when there's no URI (encrypted/event-only media).
    if (widget.uri == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tryLoadEvent(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _imageData = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Widget imageWidget = widget.animated
        ? AnimatedSwitcher(
            duration: widget.animationDuration,
            child: _buildImageWidget(context),
          )
        : _buildImageWidget(context);

    if (widget.event?.eventId != null && widget.enableHeroAnimation) {
      imageWidget = Hero(tag: widget.event!.eventId, child: imageWidget);
    }

    if (widget.isPreview) {
      return Material(
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          borderRadius: widget.rounded
              ? BorderRadius.circular(12.0)
              : BorderRadius.zero,
          onTap: widget.onTapPreview != null || widget.onTapSelectMode != null
              ? () => _onTap(context)
              : null,
          child: imageWidget,
        ),
      );
    } else {
      return imageWidget;
    }
  }

  Widget _buildImageWidget(BuildContext context) {
    // URI-based images: delegate to CachedNetworkImage
    if (widget.uri != null) {
      return _buildCachedNetworkImage(context);
    }

    // Event-based (encrypted/downloaded) or pre-loaded imageData
    final needResize = widget.event != null && !widget.noResize;
    if (_imageData == null && filePath == null) {
      return placeholder(context);
    }
    return ClipRRect(
      key: Key('${_imageData.hashCode}'),
      borderRadius: widget.rounded
          ? BorderRadius.circular(12.0)
          : BorderRadius.zero,
      child: _ImageWidget(
        filePath: filePath,
        event: widget.event,
        data: _imageData,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        needResize: needResize,
        cacheWidth: widget.cacheWidth,
        cacheHeight: widget.cacheHeight,
        isThumbnail: widget.isThumbnail,
        imageErrorWidgetBuilder: (context, error, ___) {
          _imageData = null;
          return placeholder(context);
        },
        placeholder: placeholder(context),
      ),
    );
  }

  Widget _buildCachedNetworkImage(BuildContext context) {
    final client = Matrix.of(context).client;
    final width = widget.width;
    final height = widget.height;
    final realWidth = width == null ? null : context.getCacheSize(width);
    final realHeight = height == null ? null : context.getCacheSize(height);

    final httpUri = widget.isThumbnail
        ? widget.uri!.getThumbnail(
            client,
            width: realWidth,
            height: realHeight,
            animated: widget.animated,
            method: ThumbnailMethod.scale,
          )
        : widget.uri!.getDownloadLink(client);

    return ClipRRect(
      borderRadius: widget.rounded
          ? BorderRadius.circular(12.0)
          : BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: httpUri.toString(),
        width: width,
        height: height,
        fit: widget.fit,
        filterQuality: FilterQuality.medium,
        memCacheWidth: widget.cacheWidth ?? realWidth,
        memCacheHeight: widget.cacheHeight ?? realHeight,
        placeholder: (context, url) => placeholder(context),
        errorWidget: (context, url, error) => placeholder(context),
      ),
    );
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}

class _ImageWidget extends StatelessWidget {
  final String? filePath;
  final Uint8List? data;
  final double? width;
  final Event? event;
  final double? height;
  final bool needResize;
  final BoxFit? fit;
  final ImageErrorWidgetBuilder imageErrorWidgetBuilder;
  final int? cacheWidth;
  final int? cacheHeight;
  final bool isThumbnail;
  final Widget placeholder;

  const _ImageWidget({
    this.filePath,
    this.data,
    this.width,
    this.event,
    this.height,
    required this.needResize,
    this.fit,
    required this.imageErrorWidgetBuilder,
    this.cacheWidth,
    this.cacheHeight,
    required this.isThumbnail,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (_isVideoData) {
      final matrixVideoFile = MatrixVideoFile(
        bytes: data!,
        name: event?.filename ?? '${DateTime.now().millisecondsSinceEpoch}.mp4',
        mimeType: event?.mimeType,
      );
      return FutureBuilder(
        future: event?.room.generateVideoThumbnail(matrixVideoFile),
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return placeholder;
          }

          return Image.memory(
            snapshot.data!.bytes,
            width: width,
            height: height,
            cacheWidth: cacheWidth != null
                ? cacheWidth!
                : (width != null && needResize)
                ? context.getCacheSize(width!)
                : null,
            cacheHeight: cacheHeight != null
                ? cacheHeight!
                : (height != null && needResize)
                ? context.getCacheSize(height!)
                : null,
            fit: fit,
            filterQuality: FilterQuality.medium,
            errorBuilder: imageErrorWidgetBuilder,
          );
        },
      );
    }
    return filePath != null && filePath!.isNotEmpty
        ? _ImageNativeBuilder(
            filePath: filePath,
            width: width,
            height: height,
            cacheWidth: cacheWidth,
            needResize: needResize,
            cacheHeight: cacheHeight,
            fit: fit,
            event: event,
            imageErrorWidgetBuilder: imageErrorWidgetBuilder,
          )
        : data != null
        ? event?.mimeType == TwakeMimeTypeExtension.avifMimeType
              ? AvifImage.memory(
                  data!,
                  height: height,
                  width: width,
                  fit: BoxFit.cover,
                  errorBuilder: imageErrorWidgetBuilder,
                )
              : Image.memory(
                  data!,
                  width: width,
                  height: height,
                  cacheWidth: cacheWidth != null
                      ? cacheWidth!
                      : (width != null && needResize)
                      ? context.getCacheSize(width!)
                      : null,
                  cacheHeight: cacheHeight != null
                      ? cacheHeight!
                      : (height != null && needResize)
                      ? context.getCacheSize(height!)
                      : null,
                  fit: fit,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: imageErrorWidgetBuilder,
                )
        : const SizedBox.shrink();
  }

  bool get _isVideoData {
    return event?.messageType == MessageTypes.Video &&
        data != null &&
        !isThumbnail;
  }
}

class _ImageNativeBuilder extends StatelessWidget {
  const _ImageNativeBuilder({
    this.filePath,
    this.width,
    this.height,
    this.cacheWidth,
    required this.needResize,
    this.cacheHeight,
    this.fit,
    required this.imageErrorWidgetBuilder,
    this.event,
  });

  final String? filePath;
  final Event? event;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final bool needResize;
  final int? cacheHeight;
  final BoxFit? fit;
  final ImageErrorWidgetBuilder imageErrorWidgetBuilder;

  @override
  Widget build(BuildContext context) {
    if (event?.mimeType == TwakeMimeTypeExtension.avifMimeType) {
      return AvifImage.file(
        File(filePath!),
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: imageErrorWidgetBuilder,
      );
    }
    return Image.file(
      File(filePath!),
      width: width,
      height: height,
      cacheWidth: cacheWidth != null
          ? cacheWidth!
          : (width != null && needResize)
          ? context.getCacheSize(width!)
          : null,
      cacheHeight: cacheHeight != null
          ? cacheHeight!
          : (height != null && needResize)
          ? context.getCacheSize(height!)
          : null,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: imageErrorWidgetBuilder,
    );
  }
}
