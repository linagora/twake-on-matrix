import 'dart:ui';

import 'package:fluffychat/pages/chat/send_file_dialog.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:linagora_design_flutter/images_picker/images_picker.dart' as linagora_image_picker;
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/usecase/send_image_interactor.dart';
import 'package:fluffychat/pages/chat/chat_actions.dart';
import 'package:fluffychat/pages/chat/item_actions_bottom_widget.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/permission_dialog.dart';
import 'package:fluffychat/utils/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linagora_design_flutter/images_picker/images_picker_grid.dart';
import 'package:linagora_design_flutter/images_picker/use_camera_widget.dart';
import 'package:matrix/matrix.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

typedef OnSendTap = void Function()?;

mixin ImagePickerMixin {

  final ImagePickerGridController imagePickerController = ImagePickerGridController();

  final numberSelectedImagesNotifier = ValueNotifier<int>(0);

  List<ChatActions> get listChatActions => [
    ChatActions.gallery,
    ChatActions.documents,
    ChatActions.location,
    ChatActions.contact
  ];

  void listenToSelectionInImagePicker() {
    imagePickerController.addListener(() {
      numberSelectedImagesNotifier.value = imagePickerController.selectedAssets.length;
    });
  }

  void removeAllImageSelected() {
    imagePickerController.clearAssetCounter();
    numberSelectedImagesNotifier.value = 0;
  }

  Future<PermissionStatus>? getCurrentPhotoPermission() {
    return PermissionHandlerService().requestPermissionForPhotoActions();
  }

  Future<PermissionStatus>? getCurrentCameraPermission() {
    return PermissionHandlerService().requestPermissionForCameraActions();
  }

  void showImagesPickerBottomSheetAction({
    required BuildContext context,
    required OnItemAction onItemAction,
    Room? room,
    OnSendTap onSendTap,
  }) async {
    final currentPermissionPhotos = await getCurrentPhotoPermission();
    final currentPermissionCamera = await getCurrentCameraPermission();
    if (currentPermissionPhotos != null && currentPermissionCamera != null) {
      showImagesPickerBottomSheet(
        context: context,
        permissionStatusPhotos: currentPermissionPhotos,
        permissionStatusCamera: currentPermissionCamera,
        onSendTap: onSendTap,
        room: room,
        onItemAction: onItemAction,
      ).whenComplete(() => removeAllImageSelected());
    }
  }

  Future<void> showImagesPickerBottomSheet({
    required BuildContext context,
    Room? room,
    required PermissionStatus permissionStatusPhotos,
    required PermissionStatus permissionStatusCamera,
    OnSendTap onSendTap,
    required OnItemAction onItemAction,
  }) async {
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
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 12.0, top: 16.0),
          child: Row(
            children: [
              Text(L10n.of(context)!.photoSelectedCounter(counterImage),
                style: Theme.of(context).textTheme.titleMedium,),
              const Icon(Icons.chevron_right),
              const Expanded(child: SizedBox.shrink()),
              const Icon(Icons.more_vert),
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
          if (value == 0) {
            return Container(
              padding: const EdgeInsets.only(top: 8.0, bottom: 34.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.16),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: listChatActions.map((action) {
                  return Expanded(
                    child: ItemActionOnBottom(
                      chatActions: action,
                      onItemAction: (action) => onItemAction(action),
                    ),
                  );
                }).toList()
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
                    padding: const EdgeInsets.only(right: 20.0, top: 8.0, bottom: 8.0, left: 4.0),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.16),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            onTap: () => Fluttertoast.showToast(
                              msg:  L10n.of(context)!.captionForImagesIsNotSupportYet,
                              gravity: ToastGravity.CENTER,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.tag_faces, color: LinagoraRefColors.material().neutralVariant,),
                              hintText: L10n.of(context)!.addACaption,
                            ),
                          ),
                        ),
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            InkWell(
                              borderRadius: const BorderRadius.all(Radius.circular(100)),
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
                        )
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
                        shape: CircleBorder(side: BorderSide(color: Theme.of(context).colorScheme.surface)),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      alignment: Alignment.center,
                      child: ValueListenableBuilder(
                        valueListenable: numberSelectedImagesNotifier,
                        builder: (context, value, child) {
                          return Text("$value", style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.surface,
                            letterSpacing: 0.1,
                          ),);
                        },
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
      goToSettingsWidget: Column(
        children: [
          SvgPicture.asset(ImagePaths.icPhotosSettingPermission,
            width: 40,
            height: 40,
          ),
          Text(L10n.of(context)!.tapToAllowAccessToYourGallery,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: LinagoraRefColors.material().neutral
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      cameraWidget: UseCameraWidget(
        onPressed: permissionStatusCamera == PermissionStatus.granted
          ? () => imagePickAction(context: context, room: room, locale: window.locale)
          : () => goToSettings(context),
        backgroundImage: const AssetImage("assets/verification.png"),
      ),
    );
  }

  Future<void> goToSettings(BuildContext context) async {
    final result = await showDialog<bool?>(
      context: context,
      useRootNavigator: false,
      builder: (c) => PermissionDialog(
        permission: Permission.camera,
        explainTextRequestPermission: RichText(
          text: TextSpan(
            text: '${L10n.of(context)!.tapToAllowAccessToYourCamera} ',
            style: Theme.of(context).textTheme.titleSmall,
            children: <TextSpan>[
              TextSpan(text: '${L10n.of(context)!.twake}.', style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.bold,
              )),
            ],
          ),
        ),
        icon: const Icon(Icons.camera_alt),
        onAcceptButton: () => PermissionHandlerService().goToSettingsForPermissionActions(),
      ),
    );

    if (result == true) {
      Navigator.pop(context);
    }
  }

  void imagePickAction({
    required BuildContext context, 
    Room? room, 
    required Locale locale
  }) async {
    Navigator.pop(context);
    final assetEntity = await CameraPicker.pickFromCamera(
      context,
      locale: locale,
    );
    if (assetEntity != null && assetEntity.type == AssetType.image) {
      final sendImageInteractor = getIt.get<SendImageInteractor>();
      sendImageInteractor.execute(room: room!, entity: assetEntity);
    }
  }

  void openCameraAction(BuildContext context, {required Room room}) async {
    // Make sure the textfield is unfocused before opening the camera
    FocusScope.of(context).requestFocus(FocusNode());
    final file = await ImagePicker().pickImage(source: ImageSource.camera);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (c) => SendFileDialog(
        files: [
          MatrixImageFile(
            bytes: bytes,
            name: file.path,
          )
        ],
        room: room,
      ),
    );
  }
}