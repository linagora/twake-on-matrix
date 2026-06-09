import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/extensions/xfile/xfile_extension.dart';
import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/domain/model/file_info/image_file_info.dart';
import 'package:fluffychat/domain/model/file_info/video_file_info.dart';
import 'package:fluffychat/pages/chat/chat_actions.dart';
import 'package:fluffychat/pages/chat/send_media_native_dialog/send_media_native_dialog.dart';
import 'package:fluffychat/presentation/model/file/file_asset_entity.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_manager.dart';
import 'package:fluffychat/utils/mime_type_uitls.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart' as native_picker;
import 'package:linagora_design_flutter/images_picker/images_picker.dart';
import 'package:matrix/matrix.dart';

/// Presents the preview + caption sheet for natively-picked media and resolves
/// to the user's choice (`null` = cancelled). Injectable so unit tests can drive
/// the post-pick path without a widget tree.
typedef SendMediaNativeDialogPresenter =
    Future<SendMediaNativeResult?> Function(
      BuildContext context, {
      required List<FileInfo> files,
      Room? room,
      String? pendingText,
    });

mixin SendFilesMixin {
  /// Defaults to the real full-screen dialog; overridden in tests.
  @visibleForTesting
  SendMediaNativeDialogPresenter mediaCaptionDialogPresenter =
      SendMediaNativeDialog.show;

  /// Opens the OS-native media picker via `image_picker.pickMultipleMedia()`:
  /// PHPickerViewController on iOS, the Android Photo Picker on Android 13+.
  /// Both run out-of-process, so no photo-library permission prompt is needed,
  /// and both provide the system albums/search/multi-select UI (WhatsApp-style).
  ///
  /// Selected media are mapped to typed [FileInfo] and pushed through the
  /// existing mobile upload pipeline ([UploadManager.uploadFileMobile]), which
  /// handles msgType detection, thumbnails, compression, HEIC→JPG and encryption.
  Future<void> pickAndSendMediaNative(
    BuildContext context, {
    Room? room,
    String? caption,
    Event? inReplyTo,
    VoidCallback? onSendCallback,
  }) async {
    if (room == null) return;
    final List<native_picker.XFile> files;
    try {
      files = await native_picker.ImagePicker().pickMultipleMedia();
    } on PlatformException catch (e, s) {
      Logs().e('SendFilesMixin::pickAndSendMediaNative(): $e', e, s);
      return;
    } catch (e, s) {
      // Any non-platform error (e.g. unexpected plugin failure) must not bubble
      // up as an unhandled async error on this user-triggered path.
      Logs().e('SendFilesMixin::pickAndSendMediaNative(): $e', e, s);
      return;
    }
    if (files.isEmpty) return;
    final fileInfos = files.map(_xFileToFileInfo).toList();

    // Show a preview + caption sheet (WhatsApp-style) before sending. The
    // [pendingText] (input-bar draft) prefills the caption; the dialog returns
    // the final batch caption and the possibly-trimmed file list. A null result
    // means the user cancelled → nothing is sent.
    if (!context.mounted) return;
    final result = await mediaCaptionDialogPresenter(
      context,
      files: fileInfos,
      room: room,
      pendingText: caption,
    );
    if (result == null || result.files.isEmpty) return;

    // Await the queueing pass so [onSendCallback] (clears draft/reply, scrolls)
    // runs after the placeholder events are in the timeline, not before the
    // upload begins — keeps ordering deterministic and shrinks the window where
    // the callback's async work could race a widget dispose.
    final uploadManager = getIt.get<UploadManager>();
    await uploadManager.uploadFileMobile(
      room: room,
      fileInfos: result.files,
      caption: result.caption,
      inReplyTo: inReplyTo,
    );
    onSendCallback?.call();
  }

  /// Maps a picked [native_picker.XFile] to the typed [FileInfo] expected by
  /// the upload pipeline. Returning [ImageFileInfo]/[VideoFileInfo] (rather than
  /// a bare [FileInfo]) is what lets `sendFileEventMobile` run HEIC→JPG
  /// conversion and thumbnail generation, which are gated on the concrete type.
  FileInfo _xFileToFileInfo(native_picker.XFile file) {
    final mimeType = MimeTypeUitls.instance.getTwakeMimeType(file.name);
    return switch (mimeType.msgTypeFromMime) {
      MessageTypes.Image => ImageFileInfo(
        file.name,
        filePath: file.path,
        customMimeType: mimeType,
      ),
      MessageTypes.Video => VideoFileInfo(
        file.name,
        filePath: file.path,
        customMimeType: mimeType,
      ),
      _ => FileInfo(file.name, filePath: file.path, customMimeType: mimeType),
    };
  }

  Future<void> sendMedia(
    ImagePickerGridController imagePickerController, {
    String? caption,
    Room? room,
    Event? inReplyTo,
  }) async {
    if (room == null) {
      return;
    }
    final selectedAssets = imagePickerController.sortedSelectedAssets;
    final uploadManger = getIt.get<UploadManager>();
    uploadManger.uploadMediaMobile(
      room: room,
      entities: selectedAssets.map<FileAssetEntity>((entity) {
        return FileAssetEntity.createAssetEntity(entity.asset);
      }).toList(),
      caption: caption,
      inReplyTo: inReplyTo,
    );
  }

  void sendFileAction(
    BuildContext context, {
    Room? room,
    List<FileInfo>? fileInfos,
    VoidCallback? onSendFileCallback,
    Event? inReplyTo,
    bool popContext = true,
  }) async {
    if (room == null) return;
    // [popContext] closes the legacy media-picker bottom sheet. When invoked
    // from the new input-bar popup menu there is no sheet to close, so the
    // caller passes false to avoid popping the chat route.
    if (popContext) Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      readSequential: true,
    );
    fileInfos ??= result?.xFiles.map((file) {
      return FileInfo(file.name, filePath: file.path);
    }).toList();

    if (fileInfos == null || fileInfos.isEmpty) return;
    // Await the queueing pass before clearing composer/reply state so the
    // callback runs after the placeholder events exist, mirroring
    // [pickAndSendMediaNative] and avoiding a callback-vs-dispose race.
    final uploadManger = getIt.get<UploadManager>();
    await uploadManger.uploadFileMobile(
      room: room,
      fileInfos: fileInfos,
      inReplyTo: inReplyTo,
    );
    onSendFileCallback?.call();
  }

  Future<List<MatrixFile>> pickFilesFromSystem() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: true,
      readSequential: true,
    );
    if (result == null || result.xFiles.isEmpty) return [];
    return await Future.wait(
      result.xFiles.map((file) => file.toMatrixFileOnWeb()),
    );
  }

  void onPickerTypeClick({
    required BuildContext context,
    Room? room,
    required PickerType type,
    VoidCallback? onSendFileCallback,
    Event? inReplyTo,
  }) async {
    switch (type) {
      case PickerType.gallery:
        break;
      case PickerType.documents:
        sendFileAction(
          context,
          room: room,
          onSendFileCallback: onSendFileCallback,
          inReplyTo: inReplyTo,
        );
        break;
      case PickerType.location:
        break;
      case PickerType.contact:
        break;
    }
  }
}
