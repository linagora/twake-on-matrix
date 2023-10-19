import 'package:fluffychat/pages/chat/chat_actions.dart';
import 'package:fluffychat/pages/chat/item_actions_bottom_widget.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:linagora_design_flutter/images_picker/images_picker.dart'
    as linagora_image_picker;
import 'package:linagora_design_flutter/images_picker/images_picker_grid.dart';
import 'package:linagora_design_flutter/images_picker/use_camera_widget.dart';
import 'package:matrix/matrix.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import 'common_media_picker_mixin.dart';

typedef OnCameraPicked = void Function(AssetEntity assetEntity)?;

mixin MediaPickerMixin on CommonMediaPickerMixin {
  List<PickerType> get listChatActions => [
        PickerType.gallery,
        PickerType.documents,
        PickerType.location,
        PickerType.contact,
      ];

  void showMediaPickerBottomSheetAction({
    required BuildContext context,
    required ImagePickerGridController imagePickerGridController,
    OnPickerTypeTap? onPickerTypeTap,
    Room? room,
    OnSendPhotosTap onSendTap,
    OnCameraPicked? onCameraPicked,
  }) async {
    final currentPermissionPhotos = await getCurrentMediaPermission();
    final currentPermissionCamera = await getCurrentCameraPermission();
    if (currentPermissionPhotos != null && currentPermissionCamera != null) {
      showMediasPickerBottomSheet(
        context: context,
        imagePickerController: imagePickerGridController,
        permissionStatusPhotos: currentPermissionPhotos,
        permissionStatusCamera: currentPermissionCamera,
        onSendTap: onSendTap,
        room: room,
        onPickerTypeTap: onPickerTypeTap,
        onCameraPicked: onCameraPicked,
      );
    }
  }

  Future<void> showMediasPickerBottomSheet({
    required BuildContext context,
    Room? room,
    required ImagePickerGridController imagePickerController,
    required PermissionStatus permissionStatusPhotos,
    required PermissionStatus permissionStatusCamera,
    OnSendPhotosTap onSendTap,
    OnPickerTypeTap? onPickerTypeTap,
    OnCameraPicked? onCameraPicked,
  }) async {
    final numberSelectedImagesNotifier = ValueNotifier<int>(0);
    imagePickerController.addListener(() {
      numberSelectedImagesNotifier.value =
          imagePickerController.selectedAssets.length;
    });

    return await linagora_image_picker.ImagePicker.showImagesGridBottomSheet(
      context: context,
      controller: imagePickerController,
      backgroundImageCamera: const AssetImage("assets/verification.png"),
      initialChildSize: 0.6,
      permissionStatus: permissionStatusPhotos,
      assetBackgroundColor: LinagoraSysColors.material().background,
      counterImageBuilder: (counterImage) {
        if (counterImage == 0) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
            bottom: 12.0,
            top: 16.0,
          ),
          child: Row(
            children: [
              Text(
                L10n.of(context)!.photoSelectedCounter(counterImage),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        );
      },
      expandedWidget: ValueListenableBuilder(
        valueListenable: numberSelectedImagesNotifier,
        builder: (context, value, child) {
          if (value == 0) {
            return const SizedBox(height: 90);
          }
          return child!;
        },
        child: const SizedBox(height: 50),
      ),
      bottomWidget: ValueListenableBuilder(
        valueListenable: numberSelectedImagesNotifier,
        builder: (context, value, child) {
          if (value == 0 && onPickerTypeTap != null) {
            return Container(
              padding: const EdgeInsets.only(top: 8.0, bottom: 34.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceTint
                        .withOpacity(0.16),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: listChatActions.map((action) {
                  return Expanded(
                    child: PickerTypeOnBottom(
                      pickerType: action,
                      onPickerTypeTap: onPickerTypeTap,
                    ),
                  );
                }).toList(),
              ),
            );
          }
          return child!;
        },
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    height: 64,
                    padding: const EdgeInsets.only(
                      right: 20.0,
                      top: 8.0,
                      bottom: 8.0,
                      left: 4.0,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceTint
                              .withOpacity(0.16),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            onTap: () => TwakeSnackBar.show(
                              context,
                              L10n.of(context)!.captionForImagesIsNotSupportYet,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.tag_faces,
                                color:
                                    LinagoraRefColors.material().neutralVariant,
                              ),
                              hintText: L10n.of(context)!.addACaption,
                            ),
                          ),
                        ),
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            InkWell(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(100)),
                              onTap: () {
                                if (onSendTap != null) {
                                  onSendTap();
                                }
                                Navigator.of(context).pop();
                              },
                              child: SvgPicture.asset(
                                ImagePaths.icSend,
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 12.0,
                    bottom: 2.0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: ShapeDecoration(
                        shape: CircleBorder(
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      alignment: Alignment.center,
                      child: ValueListenableBuilder(
                        valueListenable: numberSelectedImagesNotifier,
                        builder: (context, value, child) {
                          return Text(
                            "$value",
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.surface,
                                  letterSpacing: 0.1,
                                ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
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
            ? () => _pickFromCameraAction(
                  context: context,
                  imagePickerGridController: imagePickerController,
                  room: room,
                  onCameraPicked: onCameraPicked,
                )
            : () => goToSettings(context),
        backgroundImage: const AssetImage("assets/verification.png"),
      ),
    );
  }

  void _pickFromCameraAction({
    required BuildContext context,
    required ImagePickerGridController imagePickerGridController,
    OnCameraPicked? onCameraPicked,
    Room? room,
    bool onlyImage = false,
  }) async {
    final assetEntity =
        await pickMediaFromCameraAction(context: context, onlyImage: onlyImage);
    if (assetEntity != null) {
      imagePickerGridController.pickAssetFromCamera(assetEntity);

      if (onCameraPicked != null) {
        onCameraPicked(assetEntity);
      }
    }
  }
}
