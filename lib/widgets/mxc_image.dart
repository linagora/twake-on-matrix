import 'dart:io';
import 'dart:typed_data';
import 'package:fluffychat/pages/image_viewer/image_viewer.dart';
import 'package:fluffychat/presentation/enum/chat/media_viewer_popup_result_enum.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/utils/interactive_viewer_gallery.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/hero_page_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:fluffychat/config/themes.dart';
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
  final Duration retryDuration;
  final Duration animationDuration;
  final Curve animationCurve;
  final ThumbnailMethod thumbnailMethod;
  final Widget Function(BuildContext context)? placeholder;
  final String? cacheKey;
  final bool rounded;
  final void Function()? onTapPreview;
  final void Function()? onTapSelectMode;
  final ImageData? imageData;
  final bool isPreview;

  /// Enable it if the image is stretched, and you don't want to resize it
  final bool noResize;

  /// Cache for screen locally, if null, use global cache
  final Map<EventId, ImageData>? cacheMap;

  final VoidCallback? closeRightColumn;

  final int? cacheWidth;

  final int? cacheHeight;

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
    this.retryDuration = const Duration(seconds: 2),
    this.animationCurve = TwakeThemes.animationCurve,
    this.thumbnailMethod = ThumbnailMethod.scale,
    this.cacheKey,
    this.rounded = false,
    this.onTapPreview,
    this.onTapSelectMode,
    this.imageData,
    this.isPreview = false,
    this.cacheMap,
    this.noResize = false,
    this.closeRightColumn,
    this.cacheWidth,
    this.cacheHeight,
    super.key,
  });

  @override
  State<MxcImage> createState() => _MxcImageState();
}

class _MxcImageState extends State<MxcImage> {
  static const String placeholderKey = 'placeholder';
  static final Map<EventId, ImageData> _imageDataCache = {};
  ImageData? _imageDataNoCache;
  bool isLoadDone = false;
  String? filePath;

  ImageData? get _imageData {
    final cacheKey = widget.cacheKey;
    final image = cacheKey == null
        ? _imageDataNoCache
        : widget.cacheMap != null
            ? _imageDataFromLocalCache
            : _imageDataFromGlobalCache;
    return image;
  }

  ImageData? get _imageDataFromLocalCache =>
      widget.cacheKey != null && widget.cacheMap != null
          ? widget.cacheMap![widget.cacheKey]
          : null;

  ImageData? get _imageDataFromGlobalCache =>
      widget.cacheKey != null ? _imageDataCache[widget.cacheKey] : null;

  set _imageData(ImageData? data) {
    if (data == null) return;
    final cacheKey = widget.cacheKey;
    if (cacheKey == null) {
      _imageDataNoCache = data;
    } else if (widget.cacheMap != null) {
      widget.cacheMap![cacheKey] = data;
    } else {
      _imageDataCache[cacheKey] = data;
    }
  }

  bool? _isCached;

  Future<void> _load() async {
    final client = Matrix.of(context).client;
    final uri = widget.uri;
    final event = widget.event;

    if (uri != null) {
      final width = widget.width;
      final realWidth = width == null ? null : context.getCacheSize(width);
      final height = widget.height;
      final realHeight = height == null ? null : context.getCacheSize(height);

      final httpUri = widget.isThumbnail
          ? uri.getThumbnail(
              client,
              width: realWidth,
              height: realHeight,
              animated: widget.animated,
              method: widget.thumbnailMethod,
            )
          : uri.getDownloadLink(client);

      if (_isCached == null && widget.event != null) {
        final cachedData = await client.database?.getFile(
          event!.eventId,
          widget.isThumbnail ? event.thumbnailFilename : event.filename,
        );
        if (cachedData != null) {
          if (!mounted) return;
          setState(() {
            _imageData = cachedData;
            _isCached = true;
          });
          return;
        }
        _isCached = false;
      }

      final response = await http.get(httpUri);
      if (response.statusCode != 200) {
        if (response.statusCode == 404) {
          return;
        }
        throw Exception();
      }
      final remoteData = response.bodyBytes;

      if (!mounted) return;
      setState(() {
        _imageData = remoteData;
      });
      if (widget.event != null) {
        await client.database?.storeEventFile(
          widget.event!.eventId,
          event!.filename,
          remoteData,
          0,
        );
      }
    }

    if (event != null) {
      if (!PlatformInfos.isWeb) {
        final fileInfo = await event.getFileInfo(
          getThumbnail: widget.isThumbnail,
        );
        if (fileInfo != null && fileInfo.filePath.isNotEmpty) {
          setState(() {
            filePath = fileInfo.filePath;
          });
          return;
        }
      }

      final matrixFile = await event.downloadAndDecryptAttachment(
        getThumbnail: widget.isThumbnail,
      );
      if (!mounted) return;
      setState(() {
        _imageData = matrixFile.bytes;
      });
      return;
    }
  }

  void _tryLoad(_) async {
    _imageData = widget.imageData;
    if (_imageData != null) {
      setState(() {
        isLoadDone = true;
      });
      return;
    }
    try {
      await _load();
      setState(() {
        isLoadDone = true;
      });
    } catch (_) {
      if (!mounted) return;
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
              itemBuilder: ImageViewer(
                event: widget.event!,
              ),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_tryLoad);
  }

  Widget placeholder(BuildContext context) =>
      widget.placeholder?.call(context) ??
      const Center(
        key: Key(placeholderKey),
        child: CircularProgressIndicator.adaptive(),
      );

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = widget.animated
        ? AnimatedSwitcher(
            duration: widget.animationDuration,
            child: _buildImageWidget(),
          )
        : _buildImageWidget();

    if (widget.event?.eventId != null) {
      imageWidget = Hero(
        tag: widget.event!.eventId,
        child: imageWidget,
      );
    }

    if (widget.isPreview) {
      return Material(
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          borderRadius:
              widget.rounded ? BorderRadius.circular(12.0) : BorderRadius.zero,
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

  Widget _buildImageWidget() {
    final data = _imageData;
    final needResize = widget.event != null && !widget.noResize;
    return filePath == null && data == null
        ? placeholder(context)
        : ClipRRect(
            key: Key('${data.hashCode}'),
            borderRadius: widget.rounded
                ? BorderRadius.circular(12.0)
                : BorderRadius.zero,
            child: _ImageWidget(
              filePath: filePath,
              event: widget.event,
              data: data,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              needResize: needResize,
              cacheWidth: widget.cacheWidth,
              cacheHeight: widget.cacheHeight,
              imageErrorWidgetBuilder: (context, __, ___) {
                _isCached = false;
                _imageData = null;
                WidgetsBinding.instance.addPostFrameCallback(_tryLoad);
                return placeholder(context);
              },
            ),
          );
  }
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
  });

  @override
  Widget build(BuildContext context) {
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
