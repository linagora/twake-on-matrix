import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:linagora_design_flutter/images_picker/asset_counter.dart';
import 'package:linagora_design_flutter/images_picker/images_picker.dart'
    as linagora_image_picker;
import 'package:linagora_design_flutter/images_picker/images_picker_grid.dart';
import 'package:linagora_design_flutter/images_picker/use_camera_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import 'common_media_picker_mixin.dart';

mixin SingleImagePickerMixin on CommonMediaPickerMixin {
  ImagePickerGridController singleImagePickerController() =>
      ImagePickerGridController(
        AssetCounter(imagePickerMode: ImagePickerMode.single),
      );

  Future<void> showImagePickerBottomSheet(
    BuildContext context,
    PermissionStatus? permissionStatusPhotos,
    PermissionStatus? permissionStatusCamera,
    ImagePickerGridController imagePickerController,
  ) async {
    if (permissionStatusPhotos != null && permissionStatusCamera != null) {
      return await linagora_image_picker.ImagePicker.showImagesGridBottomSheet(
        context: context,
        controller: imagePickerController,
        backgroundImageCamera: const AssetImage("assets/verification.png"),
        initialChildSize: 0.6,
        permissionStatus: permissionStatusPhotos,
        assetBackgroundColor: LinagoraSysColors.material().background,
        expandedWidget: const SizedBox(height: 50),
        counterImageBuilder: (_) => const SizedBox.shrink(),
        goToSettingsWidget: Column(
          children: [
            SvgPicture.asset(
              ImagePaths.icPhotosSettingPermission,
              width: 40,
              height: 40,
            ),
            Text(
              L10n.of(context)!.tapToAllowAccessToYourGallery,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: LinagoraRefColors.material().neutral),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        cameraWidget: UseCameraWidget(
          onPressed: permissionStatusCamera == PermissionStatus.granted
              ? () => pickImageFromCamera(context, imagePickerController)
              : () => goToSettings(context),
          backgroundImage: const AssetImage("assets/verification.png"),
        ),
      );
    }
  }

  void pickImageFromCamera(
    BuildContext context,
    ImagePickerGridController imagePickerController,
  ) async {
    final assetEntity =
        await pickMediaFromCameraAction(context: context, onlyImage: true);
    if (assetEntity != null && assetEntity.type == AssetType.image) {
      imagePickerController.pickAssetFromCamera(assetEntity);
    }
  }
}
