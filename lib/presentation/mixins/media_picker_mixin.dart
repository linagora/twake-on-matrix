import 'package:auto_size_text/auto_size_text.dart';
import 'package:fluffychat/pages/chat/chat_actions.dart';
import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/pages/chat/input_bar/input_bar.dart';
import 'package:fluffychat/pages/chat/item_actions_bottom_widget.dart';
import 'package:fluffychat/pages/chat/send_file_dialog/send_file_dialog_style.dart';
import 'package:fluffychat/presentation/style/media_picker_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/permission_service.dart';
import 'package:fluffychat/utils/platform_infos.dart';
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
        //TODO: Enable when we have location and contact picker
        // PickerType.location,
        // PickerType.contact,
      ];

  final PermissionHandlerService _permissionHandlerService =
      PermissionHandlerService();

  void showMediaPickerBottomSheetAction({
    required BuildContext context,
    required ImagePickerGridController imagePickerGridController,
    OnPickerTypeTap? onPickerTypeTap,
    Room? room,
    OnSendPhotosTap onSendTap,
    OnCameraPicked? onCameraPicked,
    FocusSuggestionController? focusSuggestionController,
    TextEditingController? captionController,
    ValueKey? typeAheadKey,
  }) async {
    await getCurrentMediaPermission(context)?.then((currentPermissionPhotos) {
      if (currentPermissionPhotos != null) {
        showMediasPickerBottomSheet(
          context: context,
          imagePickerController: imagePickerGridController,
          permissionStatusPhotos: currentPermissionPhotos,
          onSendTap: onSendTap,
          room: room,
          onPickerTypeTap: onPickerTypeTap,
          onCameraPicked: onCameraPicked,
          focusSuggestionController: focusSuggestionController,
          captionController: captionController,
          typeAheadKey: typeAheadKey,
        );
      }
    }).onError((error, _) {
      Logs().e(
        "MediaPickerMixin::showMediaPickerBottomSheetAction(): error - $error",
      );
    });
  }

  Future<void> showMediasPickerBottomSheet({
    required BuildContext context,
    Room? room,
    required ImagePickerGridController imagePickerController,
    required PermissionStatus permissionStatusPhotos,
    OnSendPhotosTap onSendTap,
    OnPickerTypeTap? onPickerTypeTap,
    OnCameraPicked? onCameraPicked,
    Widget? inputBar,
    FocusSuggestionController? focusSuggestionController,
    TextEditingController? captionController,
    ValueKey? typeAheadKey,
  }) async {
    final numberSelectedImagesNotifier = ValueNotifier<int>(0);
    imagePickerController.addListener(() {
      numberSelectedImagesNotifier.value =
          imagePickerController.selectedAssets.length;
      Logs().d(
        "MediaPickerMixin::showMediasPickerBottomSheet(): ImageCounts - ${numberSelectedImagesNotifier.value}",
      );
      if (numberSelectedImagesNotifier.value == 0) {
        captionController?.clear();
      }
    });

    return await linagora_image_picker.ImagePicker.showImagesGridBottomSheet(
      context: context,
      controller: imagePickerController,
      backgroundImageCamera: MediaPickerStyle.cameraIcon,
      initialChildSize: MediaPickerStyle.initialChildSize,
      minChildSize: MediaPickerStyle.initialChildSize,
      permissionStatus: permissionStatusPhotos,
      gridPadding: MediaPickerStyle.gridPadding,
      assetBackgroundColor: LinagoraSysColors.material().background,
      counterImageBuilder: (counterImage) {
        if (counterImage == 0) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: MediaPickerStyle.textSelectedCounterPadding,
          child: Row(
            children: [
              Text(
                L10n.of(context)!.photoSelectedCounter(counterImage),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Icon(Icons.chevron_right_outlined),
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
              padding: MediaPickerStyle.itemPickerPadding,
              decoration: BoxDecoration(
                color: LinagoraSysColors.material().surface,
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
          color: LinagoraSysColors.material().background,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: MediaPickerStyle.composerPadding,
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
                          child: InputBar(
                            typeAheadKey: typeAheadKey,
                            maxLines: 5,
                            minLines: 1,
                            textInputAction: null,
                            focusSuggestionController:
                                focusSuggestionController ??
                                    FocusSuggestionController(),
                            room: room,
                            controller: captionController,
                            decoration:
                                SendFileDialogStyle.bottomBarInputDecoration(
                              context,
                            ),
                            keyboardType: TextInputType.multiline,
                            autofocus: !PlatformInfos.isMobile,
                            onSubmitted: (_) {
                              if (onSendTap != null) {
                                onSendTap();
                              }
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                        Padding(
                          padding: MediaPickerStyle.sendButtonPadding,
                          child: InkWell(
                            borderRadius:
                                MediaPickerStyle.sendButtonBorderRadius,
                            onTap: () {
                              if (onSendTap != null) {
                                onSendTap();
                              }
                              Navigator.of(context).pop();
                            },
                            child: SizedBox(
                              width: MediaPickerStyle.sendButtonSize,
                              height: MediaPickerStyle.sendButtonSize,
                              child: Stack(
                                children: [
                                  SvgPicture.asset(
                                    ImagePaths.icSend,
                                    width: MediaPickerStyle.sendIconSize,
                                    height: MediaPickerStyle.sendIconSize,
                                  ),
                                  ValueListenableBuilder(
                                    valueListenable:
                                        numberSelectedImagesNotifier,
                                    builder:
                                        (context, numberSelectedImages, child) {
                                      if (numberSelectedImages == 0 &&
                                          onPickerTypeTap != null) {
                                        return child!;
                                      }
                                      return Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width:
                                              MediaPickerStyle.counterIconSize,
                                          height:
                                              MediaPickerStyle.counterIconSize,
                                          padding:
                                              MediaPickerStyle.counterPadding,
                                          decoration: ShapeDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            shape:
                                                const CircleBorder().copyWith(
                                              side: BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                                width: MediaPickerStyle
                                                    .borderSideWidth,
                                              ),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: AutoSizeText(
                                            "$numberSelectedImages",
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surface,
                                                ),
                                            minFontSize:
                                                MediaPickerStyle.minFontSize,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
      onGoToSettings: (context) async {
        Navigator.pop(context);
        await _permissionHandlerService
            .requestPermissionForMediaActions(context);
      },
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
        onPressed: () => _onPressedCamera(
          context,
          imagePickerController,
          onCameraPicked,
        ),
        backgroundImage: const AssetImage("assets/verification.png"),
      ),
    );
  }

  void _onPressedCamera(
    BuildContext context,
    ImagePickerGridController imagePickerController,
    OnCameraPicked? onCameraPicked,
  ) async {
    final currentPermissionMicro = await getCurrentMicroPermission();
    final currentPermissionCamera = await getCurrentCameraPermission();
    if (currentPermissionMicro == PermissionStatus.granted &&
        currentPermissionCamera == PermissionStatus.granted) {
      _pickFromCameraAction(
        context: context,
        imagePickerGridController: imagePickerController,
        onCameraPicked: onCameraPicked,
      );
    } else {
      goToSettings(
        context,
        isMicrophone: currentPermissionMicro != PermissionStatus.granted,
      );
    }
  }

  void _pickFromCameraAction({
    required BuildContext context,
    required ImagePickerGridController imagePickerGridController,
    OnCameraPicked? onCameraPicked,
    bool onlyImage = false,
  }) async {
    var assetEntity =
        await pickMediaFromCameraAction(context: context, onlyImage: onlyImage);
    Logs().d(
      "MediaPickerMixin::_pickFromCameraAction(): assetEntity - $assetEntity",
    );
    if (assetEntity != null) {
      // TODO: TW-1844: Remove this when the issue https://github.com/fluttercandies/flutter_wechat_camera_picker/issues/266
      if (PlatformInfos.isAndroid) {
        assetEntity = AssetEntity(
          id: assetEntity.id,
          width: 0,
          height: 0,
          typeInt: assetEntity.typeInt,
        );
      }
      imagePickerGridController.pickAssetFromCamera(assetEntity);

      if (onCameraPicked != null) {
        onCameraPicked(assetEntity);
      }
    }
  }
}
