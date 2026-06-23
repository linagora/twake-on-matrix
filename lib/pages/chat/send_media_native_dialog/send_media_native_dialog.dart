import 'dart:io';

import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/domain/model/file_info/video_file_info.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/pages/chat/input_bar/input_bar.dart';
import 'package:fluffychat/presentation/extensions/media_thumbnail_extension.dart';
import 'package:fluffychat/presentation/widget_keys/widget_keys.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:open_file/open_file.dart';

/// Result returned by [SendMediaNativeDialog]. `null` means the user cancelled
/// (no upload should happen). On send, [files] is the kept list (oversized files
/// dropped) and [caption] is the single batch caption (empty → no caption).
class SendMediaNativeResult {
  final List<FileInfo> files;
  final String? caption;

  const SendMediaNativeResult({required this.files, this.caption});
}

/// Full-screen preview + caption sheet shown after the OS-native picker returns,
/// before pushing media through [UploadManager.uploadFileMobile].
///
/// Mirrors the WhatsApp flow: swipe between picked items, remove unwanted ones,
/// add a single caption for the batch (with @mention suggestions), then send.
/// It returns a [SendMediaNativeResult] via [Navigator.pop] and does NOT upload
/// itself — the caller keeps ownership of the mobile upload pipeline so HEIC→JPG,
/// compression and streaming stay intact.
class SendMediaNativeDialog extends StatefulWidget {
  final List<FileInfo> files;
  final String? pendingText;

  /// Needed for @mention suggestions in the caption and for generating video
  /// thumbnails / reading the server's max upload size.
  final Room? room;

  const SendMediaNativeDialog({
    super.key,
    required this.files,
    this.room,
    this.pendingText,
  });

  static Future<SendMediaNativeResult?> show(
    BuildContext context, {
    required List<FileInfo> files,
    Room? room,
    String? pendingText,
  }) {
    return Navigator.of(context).push<SendMediaNativeResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SendMediaNativeDialog(
          files: files,
          room: room,
          pendingText: pendingText,
        ),
      ),
    );
  }

  @override
  State<SendMediaNativeDialog> createState() => _SendMediaNativeDialogState();
}

class _SendMediaNativeDialogState extends State<SendMediaNativeDialog> {
  late final List<FileInfo> _files = List.of(widget.files);
  late final TextEditingController _captionController = TextEditingController(
    text: widget.pendingText ?? '',
  );
  final FocusSuggestionController _focusSuggestionController =
      FocusSuggestionController();
  final FocusNode _captionFocusNode = FocusNode();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// Server-reported max upload size in bytes (null while loading / unknown).
  int? _maxUploadSize;

  /// Cache of generated video thumbnails keyed by file path. A present key with
  /// a null value means generation was attempted and failed.
  final Map<String, MatrixImageFile?> _videoThumbnails = {};

  @override
  void initState() {
    super.initState();
    _loadMaxUploadSize();
    _generateVideoThumbnails();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _captionFocusNode.dispose();
    _focusSuggestionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadMaxUploadSize() async {
    final client = widget.room?.client;
    if (client == null) return;
    try {
      final config = await client.getConfig();
      if (!mounted) return;
      setState(() => _maxUploadSize = config.mUploadSize);
    } catch (e, s) {
      Logs().w('SendMediaNativeDialog::_loadMaxUploadSize(): $e', e, s);
    }
  }

  Future<void> _generateVideoThumbnails() async {
    final room = widget.room;
    if (room == null) return;
    for (final file in _files) {
      final path = file.filePath;
      if (file is! VideoFileInfo || path == null) continue;
      final thumbnail = await room.generateVideoThumbnailFromPath(
        path,
        videoFileName: file.fileName,
      );
      if (!mounted) return;
      setState(() => _videoThumbnails[path] = thumbnail);
    }
  }

  bool _isTooLarge(FileInfo file) =>
      _maxUploadSize != null && file.fileSize > _maxUploadSize!;

  List<FileInfo> get _sendableFiles =>
      _files.where((f) => !_isTooLarge(f)).toList();

  void _removeCurrent() {
    if (_files.length <= 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _files.removeAt(_currentPage);
      if (_currentPage >= _files.length) {
        _currentPage = _files.length - 1;
      }
    });
    // Resync the PageController after the PageView rebuilds with fewer pages,
    // otherwise removing the last page leaves it pointing out of bounds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    });
  }

  void _send() {
    final sendable = _sendableFiles;
    if (sendable.isEmpty) return;
    final caption = _captionController.text.trim();
    Navigator.of(context).pop(
      SendMediaNativeResult(
        files: sendable,
        caption: caption.isEmpty ? null : caption,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSendable = _sendableFiles.isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        // The app's AppBarTheme forces a grey icon color that wins over
        // foregroundColor; set white explicitly so the controls read on black.
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          color: Colors.white,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _files.length > 1
            ? Text(
                '${_currentPage + 1}/${_files.length}',
                style: const TextStyle(color: Colors.white),
              )
            : null,
        actions: [
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.delete_outline),
            onPressed: _removeCurrent,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _files.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) {
                final file = _files[i];
                return _MediaPreview(
                  file: file,
                  videoThumbnail: _videoThumbnails[file.filePath],
                  tooLargeMessage: _isTooLarge(file)
                      ? L10n.of(context)!.fileIsTooBigForServer
                      : null,
                );
              },
            ),
          ),
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LinagoraSpacing.base * 1.5,
                  vertical: LinagoraSpacing.base,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: InkWell(
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        onTap: () => _captionFocusNode.requestFocus(),
                        child: InputBar(
                          typeAheadKey:
                              ChatKeys.sendFileDialogTypeAhead.valueKey,
                          minLines: 1,
                          maxLines: 5,
                          room: widget.room,
                          controller: _captionController,
                          focusSuggestionController: _focusSuggestionController,
                          typeAheadFocusNode: _captionFocusNode,
                          keyboardType: TextInputType.multiline,
                          textInputAction: null,
                          decoration: InputDecoration(
                            hintText: L10n.of(context)!.enterCaption,
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: hasSendable ? _send : null,
                      backgroundColor: hasSendable
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).disabledColor,
                      tooltip: L10n.of(context)!.send,
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  final FileInfo file;
  final MatrixImageFile? videoThumbnail;
  final String? tooLargeMessage;

  const _MediaPreview({
    required this.file,
    this.videoThumbnail,
    this.tooLargeMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildPreview(),
        if (tooLargeMessage != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Theme.of(context).colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      tooLargeMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreview() {
    final path = file.filePath;
    if (file is VideoFileInfo) {
      final thumbnailBytes = videoThumbnail?.bytes;
      return Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnailBytes != null)
            Image.memory(thumbnailBytes, fit: BoxFit.contain)
          else
            const SizedBox.shrink(),
          Center(
            child: GestureDetector(
              onTap: path != null ? () => OpenFile.open(path) : null,
              child: const Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 72,
              ),
            ),
          ),
        ],
      );
    }
    if (path == null) {
      return const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white54),
      );
    }
    // No InteractiveViewer here: its pan gesture would swallow the horizontal
    // drag and block the parent PageView from swiping image-to-image.
    return Center(child: Image.file(File(path), fit: BoxFit.contain));
  }
}
