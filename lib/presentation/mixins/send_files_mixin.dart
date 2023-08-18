import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/usecase/send_file_interactor.dart';
import 'package:fluffychat/domain/usecase/send_file_on_web_interactor.dart';
import 'package:fluffychat/domain/usecase/send_images_interactor.dart';
import 'package:fluffychat/pages/chat/chat_actions.dart';
import 'package:fluffychat/presentation/model/file/file_asset_entity.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/images_picker/images_picker.dart';
import 'package:matrix/matrix.dart';

import 'media_picker_mixin.dart';

mixin SendFilesMixin on MediaPickerMixin {
  Future<void> sendImages(
    ImagePickerGridController imagePickerController, {
    Room? room,
  }) async {
    if (room == null) {
      return;
    }
    final selectedAssets = imagePickerController.sortedSelectedAssets;
    final sendImagesInteractor = getIt.get<SendImagesInteractor>();
    await sendImagesInteractor.execute(
      room: room,
      entities: selectedAssets.map<FileAssetEntity>((entity) {
        return FileAssetEntity.createAssetEntity(entity.asset);
      }).toList(),
    );
  }

  void sendFileAction(
    BuildContext context, {
    Room? room,
  }) async {
    if (room == null) {}
    final sendFileInteractor = getIt.get<SendFileInteractor>();
    Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles(
      withReadStream: true,
    );
    if (result == null && result?.files.isEmpty == true) return;

    sendFileInteractor.execute(room: room!, filePickerResult: result!);
  }

  void sendFileOnWebAction(
    BuildContext context, {
    Room? room,
  }) async {
    if (room == null) {}
    final sendFileOnWebInteractor = getIt.get<SendFileOnWebInteractor>();
    final result = await FilePicker.platform.pickFiles(
      withData: true,
    );
    if (result == null && result?.files.isEmpty == true) return;

    sendFileOnWebInteractor.execute(room: room!, filePickerResult: result!);
  }

  void onPickerTypeClick({
    required BuildContext context,
    Room? room,
    required PickerType type,
  }) async {
    switch (type) {
      case PickerType.gallery:
        break;
      case PickerType.documents:
        sendFileAction(context, room: room);
        break;
      case PickerType.location:
        break;
      case PickerType.contact:
        break;
    }
  }
}
