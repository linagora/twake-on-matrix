import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/extensions/xfile/xfile_extension.dart';
import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/pages/chat/chat_actions.dart';
import 'package:fluffychat/presentation/model/file/file_asset_entity.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_manager.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/images_picker/images_picker.dart';
import 'package:matrix/matrix.dart';

mixin SendFilesMixin {
  Future<void> sendMedia(
    ImagePickerGridController imagePickerController, {
    String? caption,
    Room? room,
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
    );
  }

  void sendFileAction(
    BuildContext context, {
    Room? room,
    List<FileInfo>? fileInfos,
    VoidCallback? onSendFileCallback,
  }) async {
    if (room == null) {}
    Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles(
      withReadStream: true,
      allowMultiple: true,
    );
    fileInfos ??= await Future.wait(
      result?.xFiles.map((file) async {
            final matrixFile = await file.toMatrixFileOnMobile();
            return FileInfo.fromMatrixFile(matrixFile);
          }) ??
          [],
    );

    if (fileInfos.isEmpty == true) return;
    onSendFileCallback?.call();
    final uploadManger = getIt.get<UploadManager>();
    uploadManger.uploadFileMobile(room: room!, fileInfos: fileInfos);
  }

  Future<List<MatrixFile>> pickFilesFromSystem() async {
    final result = await FilePicker.platform.pickFiles(
      withData: false,
      allowMultiple: true,
      withReadStream: true,
    );
    if (result == null || result.files.isEmpty) return [];
    return await Future.wait(
      result.xFiles.map((file) => file.toMatrixFileOnWeb()),
    );
  }

  void onPickerTypeClick({
    required BuildContext context,
    Room? room,
    required PickerType type,
    VoidCallback? onSendFileCallback,
  }) async {
    switch (type) {
      case PickerType.gallery:
        break;
      case PickerType.documents:
        sendFileAction(
          context,
          room: room,
          onSendFileCallback: onSendFileCallback,
        );
        break;
      case PickerType.location:
        break;
      case PickerType.contact:
        break;
    }
  }
}
