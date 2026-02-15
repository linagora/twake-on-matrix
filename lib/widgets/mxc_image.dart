import 'dart:io';
import 'dart:typed_data';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/data/cache/mxc_cache_manager.dart';
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
  final bool rounded;
  final void Function()? onTapPreview;
  final void Function()? onTapSelectMode;
  final ImageData? imageData;
  final bool isPreview;
  final bool enableHeroAnimation;
  final bool noResize;
  final VoidCallback? closeRightColumn;
  final int? cacheWidth;
  final int? cacheHeight;
  final bool keepAlive;

  // DEPRECATED: Use unified cache instead
  @Deprecated('Local cacheMap no longer needed with unified cache')
  final Map<String, ImageData>? cacheMap;
  @Deprecated('cacheKey auto-generated from MXC URI')
  final String? cacheKey;

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
    @Deprecated('Use unified cache') this.cacheKey,
    this.rounded = false,
    this.onTapPreview,
    this.onTapSelectMode,
    this.imageData,
    this.isPreview = false,
    @Deprecated('Use unified cache') this.cacheMap,
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
  static const String _placeholderKey = 'placeholder';

  final MxcCacheManager _cacheManager = getIt<MxcCacheManager>();

  ImageData? _imageData;
  String? _filePath;
  bool _isLoadDone = false;

  Uri? get _mxcUri => widget.uri ?? _extractMxcFromEvent();

  Uri? _extractMxcFromEvent() {
    final event = widget.event;
    if (event == null) return null;

    if (widget.isThumbnail) {
      final thumbnail = event.content
          .tryGetMap<String, dynamic>('info')
          ?.tryGet<String>('thumbnail_url');
      if (thumbnail != null) return Uri.tryParse(thumbnail);
    }
    final url = event.content.tryGet<String>('url');
    if (url != null) return Uri.tryParse(url);
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadImage();
    });
  }

  @override
  void dispose() {
    _imageData = null;
    super.dispose();
  }

  Future<void> _loadImage({int maxRetry = 3}) async {
    // Use pre-provided imageData if available
    if (widget.imageData != null) {
      _setLoadResult(widget.imageData, null);
      return;
    }

    final mxcUri = _mxcUri;
    if (mxcUri == null) return;

    // Capture context-dependent values before any await
    final cacheWidth = _cacheWidth;
    final cacheHeight = _cacheHeight;
    final httpUri = _getHttpUri(mxcUri);

    try {
      // Step 1: Check unified cache (with httpUri for SWR)
      final cacheResult = await _cacheManager.get(
        mxcUri,
        width: cacheWidth,
        height: cacheHeight,
        isThumbnail: widget.isThumbnail,
        httpUri: httpUri,
      );

      if (cacheResult.isHit) {
        _setLoadResult(cacheResult.bytes, null);
        return;
      }

      // Step 2: Download from network
      final downloadResult = await _downloadMedia(
        mxcUri,
        httpUri,
        cacheWidth,
        cacheHeight,
      );
      if (downloadResult == null) return;

      // Step 3: Store in unified cache
      await _cacheManager.put(
        mxcUri,
        downloadResult.bytes,
        mediaType: downloadResult.mimeType ?? 'application/octet-stream',
        width: cacheWidth,
        height: cacheHeight,
        isThumbnail: widget.isThumbnail,
        etag: downloadResult.etag,
        lastModified: downloadResult.lastModified,
      );

      _setLoadResult(downloadResult.bytes, downloadResult.filePath);
    } catch (e, s) {
      Logs().e('MxcImage: load failed for $mxcUri', e, s);
      if (mounted && !_isLoadDone) {
        // Retry once after delay
        await Future.delayed(widget.retryDuration);
        if (mounted && maxRetry > 0) _loadImage(maxRetry: maxRetry - 1);
      }
    }
  }

  /// Calculate HTTP URI for downloading or validating MXC content
  Uri? _getHttpUri(Uri mxcUri) {
    final client = Matrix.of(context).client;
    return widget.isThumbnail
        ? mxcUri.getThumbnail(
            client,
            width: _cacheWidth,
            height: _cacheHeight,
            animated: widget.animated,
            method: widget.thumbnailMethod,
          )
        : mxcUri.getDownloadLink(client);
  }

  Future<_DownloadResult?> _downloadMedia(
    Uri mxcUri,
    Uri? httpUri,
    int? cacheWidth,
    int? cacheHeight,
  ) async {
    final event = widget.event;

    // Path 1: Download via Event (handles E2EE decryption)
    if (event != null) {
      // Try local file first (mobile)
      if (!PlatformInfos.isWeb) {
        final fileInfo = await event.getFileInfo(
          getThumbnail: widget.isThumbnail,
        );
        if (fileInfo != null) {
          final bytes =
              fileInfo.bytes ??
              (fileInfo.filePath != null
                  ? await File(fileInfo.filePath!).readAsBytes()
                  : null);
          if (bytes != null) {
            return _DownloadResult(
              bytes: bytes,
              filePath: fileInfo.filePath,
              mimeType: event.mimeType,
            );
          }
        }
      }

      final matrixFile = await event.downloadAndDecryptAttachment(
        getThumbnail: widget.isThumbnail,
      );

      if (!matrixFile.isImage() && !event.isVideoOrImage) {
        return null;
      }

      return _DownloadResult(
        bytes: matrixFile.bytes,
        mimeType: matrixFile.mimeType,
      );
    }

    // Path 2: Download via URI directly (with HTTP 304 support)
    if (httpUri == null) return null;

    // Check for cached metadata to enable conditional GET
    final cachedMetadata = await _cacheManager.getMetadata(
      mxcUri,
      width: cacheWidth,
      height: cacheHeight,
      isThumbnail: widget.isThumbnail,
    );

    // Build request headers with conditional headers if available
    final headers = <String, String>{};
    if (cachedMetadata != null && cachedMetadata.hasValidationHeaders) {
      if (cachedMetadata.etag != null) {
        headers['If-None-Match'] = cachedMetadata.etag!;
      }
      if (cachedMetadata.lastModified != null) {
        headers['If-Modified-Since'] = cachedMetadata.lastModified!;
      }
      Logs().d(
        'MxcImage: conditional GET for $mxcUri with ${headers.keys.join(", ")}',
      );
    }

    final response = await http
        .get(httpUri, headers: headers)
        .timeout(const Duration(seconds: 30));

    // Handle HTTP 304 Not Modified - content unchanged, use cache
    if (response.statusCode == 304) {
      Logs().d('MxcImage: HTTP 304 for $mxcUri, using cached content');
      final cachedBytes = await _cacheManager.getFromDisk(
        mxcUri,
        width: cacheWidth,
        height: cacheHeight,
        isThumbnail: widget.isThumbnail,
      );

      if (cachedBytes != null) {
        return _DownloadResult(
          bytes: cachedBytes,
          mimeType: 'application/octet-stream', // Safe fallback
          etag: cachedMetadata?.etag,
          lastModified: cachedMetadata?.lastModified,
        );
      }

      // Cache miss after 304 (race condition) - retry unconditional GET
      Logs().w('MxcImage: 304 but no cache, retrying unconditional GET');
      final retryResponse = await http
          .get(httpUri)
          .timeout(const Duration(seconds: 30));
      if (retryResponse.statusCode != 200) {
        throw Exception(
          'Failed to download image: ${retryResponse.statusCode} ${retryResponse.reasonPhrase}',
        );
      }
      return _DownloadResult(
        bytes: retryResponse.bodyBytes,
        mimeType: retryResponse.headers['content-type'] ?? 'image/png',
        etag: retryResponse.headers['etag'],
        lastModified: retryResponse.headers['last-modified'],
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download image: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    return _DownloadResult(
      bytes: response.bodyBytes,
      mimeType: response.headers['content-type'] ?? 'image/png',
      etag: response.headers['etag'],
      lastModified: response.headers['last-modified'],
    );
  }

  void _setLoadResult(ImageData? bytes, String? filePath) {
    if (!mounted) return;
    setState(() {
      _imageData = bytes;
      _filePath = filePath;
      _isLoadDone = true;
    });
  }

  int? get _cacheWidth {
    if (widget.cacheWidth != null) return widget.cacheWidth;
    final width = widget.width;
    if (width == null) return null;
    return context.getCacheSize(width);
  }

  int? get _cacheHeight {
    if (widget.cacheHeight != null) return widget.cacheHeight;
    final height = widget.height;
    if (height == null) return null;
    return context.getCacheSize(height);
  }

  void _onTap(BuildContext context) async {
    if (widget.onTapPreview != null) {
      widget.onTapPreview!();
      final result =
          await Navigator.of(context, rootNavigator: PlatformInfos.isWeb).push(
            HeroPageRoute(
              builder: (context) => InteractiveViewerGallery(
                itemBuilder: PlatformInfos.isMobile
                    ? MediaViewer(event: widget.event!)
                    : ImageViewer(event: widget.event!),
              ),
            ),
          );
      if (result == MediaViewerPopupResultEnum.closeRightColumnFlag) {
        widget.closeRightColumn?.call();
      }
    } else if (widget.onTapSelectMode != null) {
      widget.onTapSelectMode!();
    }
  }

  Widget _placeholder(BuildContext context) =>
      widget.placeholder?.call(context) ??
      const Center(
        key: Key(_placeholderKey),
        child: CupertinoActivityIndicator(),
      );

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
    }

    return imageWidget;
  }

  Widget _buildImageWidget(BuildContext context) {
    if (_imageData == null && _filePath == null) {
      return _placeholder(context);
    }

    final needResize = widget.event != null && !widget.noResize;

    return ClipRRect(
      key: Key('${_imageData.hashCode}'),
      borderRadius: widget.rounded
          ? BorderRadius.circular(12.0)
          : BorderRadius.zero,
      child: _ImageWidget(
        filePath: _filePath,
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _imageData = null;
              });
            }
          });
          return _placeholder(context);
        },
        placeholder: _placeholder(context),
      ),
    );
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}

class _DownloadResult {
  final Uint8List bytes;
  final String? filePath;
  final String? mimeType;
  final String? etag;
  final String? lastModified;

  const _DownloadResult({
    required this.bytes,
    this.filePath,
    this.mimeType,
    this.etag,
    this.lastModified,
  });
}

// _ImageWidget and _ImageNativeBuilder remain unchanged
// (they only render already-loaded bytes)
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
      return _buildVideoThumbnail(context);
    }

    if (filePath != null && filePath!.isNotEmpty) {
      return _ImageNativeBuilder(
        filePath: filePath,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        needResize: needResize,
        cacheHeight: cacheHeight,
        fit: fit,
        event: event,
        imageErrorWidgetBuilder: imageErrorWidgetBuilder,
      );
    }

    if (data == null) return const SizedBox.shrink();

    if (event?.mimeType == TwakeMimeTypeExtension.avifMimeType) {
      return AvifImage.memory(
        data!,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: imageErrorWidgetBuilder,
      );
    }

    return Image.memory(
      data!,
      width: width,
      height: height,
      cacheWidth: _effectiveCacheWidth(context),
      cacheHeight: _effectiveCacheHeight(context),
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: imageErrorWidgetBuilder,
    );
  }

  bool get _isVideoData =>
      event?.messageType == MessageTypes.Video && data != null && !isThumbnail;

  int? _effectiveCacheWidth(BuildContext context) {
    if (cacheWidth != null) return cacheWidth;
    if (width != null && needResize) return context.getCacheSize(width!);
    return null;
  }

  int? _effectiveCacheHeight(BuildContext context) {
    if (cacheHeight != null) return cacheHeight;
    if (height != null && needResize) return context.getCacheSize(height!);
    return null;
  }

  Widget _buildVideoThumbnail(BuildContext context) {
    final matrixVideoFile = MatrixVideoFile(
      bytes: data!,
      name: event?.filename ?? '${DateTime.now().millisecondsSinceEpoch}.mp4',
      mimeType: event?.mimeType,
    );

    return FutureBuilder<MatrixImageFile?>(
      future: event?.room.generateVideoThumbnail(matrixVideoFile),
      builder: (context, snapshot) {
        if (snapshot.data == null) return placeholder;

        return Image.memory(
          snapshot.data!.bytes,
          width: width,
          height: height,
          cacheWidth: _effectiveCacheWidth(context),
          cacheHeight: _effectiveCacheHeight(context),
          fit: fit,
          filterQuality: FilterQuality.medium,
          errorBuilder: imageErrorWidgetBuilder,
        );
      },
    );
  }
}

class _ImageNativeBuilder extends StatelessWidget {
  final String? filePath;
  final Event? event;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final bool needResize;
  final int? cacheHeight;
  final BoxFit? fit;
  final ImageErrorWidgetBuilder imageErrorWidgetBuilder;

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
      cacheWidth:
          cacheWidth ??
          (width != null && needResize ? context.getCacheSize(width!) : null),
      cacheHeight:
          cacheHeight ??
          (height != null && needResize ? context.getCacheSize(height!) : null),
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: imageErrorWidgetBuilder,
    );
  }
}
