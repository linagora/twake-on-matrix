import 'package:fluffychat/presentation/style/media_picker_style.dart';
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
    ImagePickerGridController imagePickerController, {
    RequestType type = RequestType.image,
  }) async {
    if (permissionStatusPhotos != null) {
      return await linagora_image_picker.ImagePicker.showImagesGridBottomSheet(
        context: context,
        controller: imagePickerController,
        backgroundImageCamera: const AssetImage("assets/verification.png"),
        initialChildSize: MediaPickerStyle.initialChildSize,
        permissionStatus: permissionStatusPhotos,
        assetBackgroundColor: LinagoraSysColors.material().background,
        expandedWidget:
            const SizedBox(height: MediaPickerStyle.expandedWidgetHeight),
        counterImageBuilder: (_) => const SizedBox.shrink(),
        goToSettingsWidget: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              ImagePaths.icPhotosSettingPermission,
              width: MediaPickerStyle.photoPermissionIconSize,
              height: MediaPickerStyle.photoPermissionIconSize,
            ),
            Text(
              L10n.of(context)!.tapToAllowAccessToYourGallery,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: LinagoraRefColors.material().neutral,
                    fontWeight: MediaPickerStyle.photoPermissionFontWeight,
                    fontSize: MediaPickerStyle.photoPermissionFontSize,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        cameraWidget: UseCameraWidget(
          onPressed: () async {
            final currentPermissionCamera = await getCurrentCameraPermission();
            if (currentPermissionCamera == PermissionStatus.granted) {
              pickImageFromCamera(context, imagePickerController);
            } else {
              goToSettings(context);
            }
          },
          backgroundImage: const AssetImage("assets/verification.png"),
        ),
        type: type,
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
