import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';

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
  final Function(Uint8List uint8list)? callbackImage;
  final Uint8List? imageData;

  const MxcImage({
    this.uri,
    this.event,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.isThumbnail = true,
    this.animated = false,
    this.animationDuration = FluffyThemes.animationDuration,
    this.retryDuration = const Duration(seconds: 2),
    this.animationCurve = FluffyThemes.animationCurve,
    this.thumbnailMethod = ThumbnailMethod.scale,
    this.cacheKey,
    this.rounded = false,
    this.callbackImage,
    this.imageData,
    Key? key,
  }) : super(key: key);

  @override
  State<MxcImage> createState() => _MxcImageState();
}

class _MxcImageState extends State<MxcImage> {
  static final Map<String, Uint8List> _imageDataCache = {};
  Uint8List? _imageDataNoCache;

  bool isLoadDone = false;

  Uint8List? get _imageData {
    final cacheKey = widget.cacheKey;
    final image = cacheKey == null ? _imageDataNoCache : _imageDataCache[cacheKey];
    if (image != null ) {
      widget.callbackImage?.call(image);
    }
    return image;
  }

  set _imageData(Uint8List? data) {
    if (data == null) return;
    final cacheKey = widget.cacheKey;
    cacheKey == null
        ? _imageDataNoCache = data
        : _imageDataCache[cacheKey] = data;
  }

  bool? _isCached;

  Future<void> _load() async {
    final client = Matrix.of(context).client;
    final uri = widget.uri;
    final event = widget.event;

    if (uri != null) {
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final width = widget.width;
      final realWidth = width == null ? null : width * devicePixelRatio;
      final height = widget.height;
      final realHeight = height == null ? null : height * devicePixelRatio;

      final httpUri = widget.isThumbnail
          ? uri.getThumbnail(
              client,
              width: realWidth,
              height: realHeight,
              animated: widget.animated,
              method: widget.thumbnailMethod,
            )
          : uri.getDownloadLink(client);

      final storeKey = widget.isThumbnail ? httpUri : uri;

      if (_isCached == null) {
        final cachedData = await client.database?.getFile(storeKey);
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
      await client.database?.storeFile(storeKey, remoteData, 0);
    }

    if (event != null) {
      final data = await event.downloadAndDecryptAttachment(
        getThumbnail: widget.isThumbnail,
      );
      if (data.detectFileType is MatrixImageFile) {
        if (!mounted) return;
        setState(() {
          _imageData = data.bytes;
        });
        return;
      }
    }
  }

  void _tryLoad(_) async {
    if (widget.imageData != null) {
      _imageData = widget.imageData;
      isLoadDone = true;
      return;
    }
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
      await Future.delayed(widget.retryDuration);
      _tryLoad(_);
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
        child: CircularProgressIndicator.adaptive(),
      );

  @override
  Widget build(BuildContext context) {
    return widget.animated
      ? AnimatedCrossFade(
        duration: widget.animationDuration,
        crossFadeState: isLoadDone ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: SizedBox(
          width: widget.width,
          height: widget.height,
        ),
        secondChild:_buildImageWidget())
      : _buildImageWidget();
  }

  Widget _buildImageWidget() {
    final data = _imageData;
    return data == null || data.isEmpty
      ? placeholder(context)
      : ClipRRect(
          borderRadius: widget.rounded
            ? BorderRadius.circular(12.0)
            : BorderRadius.zero,
          child: Image.memory(
            data,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, __, ___) {
              _isCached = false;
              _imageData = null;
              WidgetsBinding.instance.addPostFrameCallback(_tryLoad);
              return placeholder(context);
            }));
  }
}
