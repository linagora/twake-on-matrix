
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/usecase/send_file_interactor.dart';
import 'package:fluffychat/domain/usecase/send_image_interactor.dart';
import 'package:fluffychat/domain/usecase/send_images_interactor.dart';
import 'package:fluffychat/pages/chat/chat_actions.dart';
import 'package:fluffychat/presentation/mixins/image_picker_mixin.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/images_picker/model/indexed_asset_entity.dart';
import 'package:matrix/matrix.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

mixin SendFilesMixin on ImagePickerMixin {
  void sendImage({required Room room, required AssetEntity asset}) {
    final sendImageInteractor = getIt.get<SendImageInteractor>();
    if (asset.type == AssetType.image) {
      sendImageInteractor.execute(room: room, entity: asset);
      removeAllImageSelected();
    }
  }

  Future<void> sendImages({Room? room, List<IndexedAssetEntity>? assets}) async {
    if (room == null) {
      return ;
    }
    final selectedAssets = assets ?? imagePickerController.sortedSelectedAssets;
    final sendImagesInteractor = getIt.get<SendImagesInteractor>();
    await sendImagesInteractor.execute(
      room: room,
      entities: selectedAssets
        .map<AssetEntity>((entity) => entity.asset)
        .toList()
    );

    removeAllImageSelected();
  }

  void sendFileAction(
    BuildContext context, 
    {
      Room? room,
    }) async {
    if (room == null) {

    }
    final sendFileInteractor = getIt.get<SendFileInteractor>();
    Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles(
      withReadStream: true,
    );
    if (result == null && result?.files.isEmpty == true) return;

    sendFileInteractor.execute(room: room!, filePickerResult: result!);
  }

  void onClickItemAction({
    required BuildContext context,
    Room? room,
    required ChatActions action,
  }) async {
    switch (action) {
      case ChatActions.gallery:
        break;
      case ChatActions.documents:
        sendFileAction(context, room: room);
        break;
      case ChatActions.location:
        break;
      case ChatActions.contact:
        break;
    }
  }
}