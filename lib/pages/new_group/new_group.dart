import 'dart:async';
import 'dart:ui';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/routes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/domain/app_state/room/create_new_group_chat_state.dart';
import 'package:fluffychat/domain/app_state/room/upload_content_state.dart';
import 'package:fluffychat/domain/model/room/create_new_group_chat_request.dart';
import 'package:fluffychat/domain/usecase/room/create_new_group_chat_interactor.dart';
import 'package:fluffychat/domain/usecase/room/upload_content_interactor.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/permission_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/images_picker/images_picker.dart' as linagora_design_flutter;
import 'package:fluffychat/pages/new_group/selected_contacts_map_change_notiifer.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/mixin/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/new_group/new_group_chat_info.dart';
import 'package:fluffychat/pages/new_group/new_group_info_controller.dart';
import 'package:fluffychat/pages/new_private_chat/fetch_contacts_controller.dart';
import 'package:fluffychat/pages/new_private_chat/search_contacts_controller.dart';
import 'package:fluffychat/widgets/matrix.dart';

import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/pages/new_group/new_group_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vrouter/vrouter.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class NewGroup extends StatefulWidget {
  const NewGroup({Key? key}) : super(key: key);

  @override
  NewGroupController createState() => NewGroupController();
}

class NewGroupController extends State<NewGroup>
  with ComparablePresentationContactMixin {
  final searchContactsController = SearchContactsController();
  final fetchContactsController = FetchContactsController();
  final uploadContentInteractor = getIt.get<UploadContentInteractor>();
  final createNewGroupChatInteractor = getIt.get<CreateNewGroupChatInteractor>();
  final contactStreamController = StreamController<Either<Failure, GetContactsSuccess>>();
  final groupNameTextEditingController = TextEditingController();
  final uploadAvatarNewGroupChatNotifier = ValueNotifier<Either<Failure, Success>?>(null);
  final createRoomStateNotifier = ValueNotifier<Either<Failure, Success>?>(null);

  final selectedContactsMapNotifier = SelectedContactsMapChangeNotifier();
  final haveGroupNameNotifier = ValueNotifier(false);
  final isEnableEEEncryptionNotifier = ValueNotifier(true);
  final ImagePickerGridController imagePickerController = ImagePickerGridController();
  final numberSelectedImagesNotifier = ValueNotifier<int>(0);

  final int maxFileSizeDefaultInMB = 5 * 1024 * 1024;

  final groupNameFocusNode = FocusNode();
  StreamSubscription? uploadContentInteractorStreamSubscription;
  StreamSubscription? createNewGroupChatInteractorStreamSubscription;

  String groupName = "";
  Uri? uriAvatar;

  @override
  void initState() {
    super.initState();
    searchContactsController.init();
    listenContactsStartList();
    listenSearchContacts();
    listenGroupNameChanged();
    _registerListenerForSelectedImagesChanged();
    fetchContactsController.fetchCurrentTomContacts();
    fetchContactsController.listenForScrollChanged(fetchContactsController: fetchContactsController);
    searchContactsController.onSearchKeywordChanged = (searchKey) {
      disableLoadMoreInSearch();
    };
  }

  void disableLoadMoreInSearch() {
    fetchContactsController.allowLoadMore = searchContactsController.searchKeyword.isEmpty;
  }

  @override
  void dispose() {
    super.dispose();
    contactStreamController.close();
    searchContactsController.dispose();
    fetchContactsController.dispose();
    groupNameTextEditingController.dispose();
    imagePickerController.dispose();
    selectedContactsMapNotifier.dispose();
    haveGroupNameNotifier.dispose();
    uploadContentInteractorStreamSubscription?.cancel();
    createNewGroupChatInteractorStreamSubscription?.cancel();
  }

  void listenContactsStartList() {
    fetchContactsController.streamController.stream.listen((event) {
      Logs().d('NewGroupController::fetchContacts() - event: $event');
      contactStreamController.add(event);
    });
  }

  void listenSearchContacts() {
    searchContactsController.lookupStreamController.stream.listen((event) {
      Logs().d('NewGroupController::_fetchRemoteContacts() - event: $event');
      contactStreamController.add(event);
    });
  }

  void onCloseSearchTapped() {
    searchContactsController.onCloseSearchTapped();
    fetchContactsController.haveMoreCountactsNotifier.value = false;
  }

  Iterable<PresentationContact> get contactsList 
    => selectedContactsMapNotifier.contactsList;

  Set<PresentationContact> getAllContactsGroupChat() {
    final newContactsList = {
      PresentationContact(
        displayName: "You",
        matrixId: Matrix.of(context).client.userID,
      )
    };
    newContactsList.addAll(getSelectedValidContacts(contactsList));
    return newContactsList;
  }

  void moveToNewGroupInfoScreen() async {
    groupNameFocusNode.unfocus();
    await showGeneralDialog(
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      context: context,
      useRootNavigator: false,
      barrierColor: Colors.white,
      transitionBuilder: (context, animation1, animation2, widget) {
        return AppRoutes.rightToLeftTransition(
          animation1,
          animation2,
          NewGroupChatInfo(
            contactsList: getAllContactsGroupChat(),
            newGroupController: this,
          )
        );
      },
    );
  }

  void uploadAvatarNewGroupChat({
    required Client matrixClient,
    required AssetEntity entity,
  }) {
    uploadContentInteractorStreamSubscription = uploadContentInteractor.execute(
      matrixClient: matrixClient,
      entity: entity,
    ).listen(
      (event) => _handleUploadAvatarNewGroupChatOnData(context, event),
      onDone: _handleUploadAvatarNewGroupChatOnDone,
      onError: _handleUploadAvatarNewGroupChatOnError
    );
  }

  void createNewGroupChatAction({
    required Client matrixClient,
    required CreateNewGroupChatRequest createNewGroupChatRequest,
  }) {
    createNewGroupChatInteractorStreamSubscription = createNewGroupChatInteractor.execute(
      matrixClient: matrixClient,
      createNewGroupChatRequest: createNewGroupChatRequest,
    ).listen(
      (event) => _handleCreateNewGroupChatChatOnData(context, event),
      onDone: _handleCreateNewGroupChatOnDone,
      onError: _handleCreateNewGroupChatOnError
    );
  }

  void _handleUploadAvatarNewGroupChatOnData(BuildContext context, Either<Failure, Success> event) {
    Logs().d('NewGroupController::_handleUploadAvatarNewGroupChatOnData()');
    uploadAvatarNewGroupChatNotifier.value = event;
    event.fold(
      (failure) {
        Logs().e('NewGroupController::_handleUploadAvatarNewGroupChatOnData() - failure: $failure');
        removeAllImageSelected();
      },
      (success) {
        Logs().d('NewGroupController::_handleUploadAvatarNewGroupChatOnData() - success: $success');
        if (success is UploadContentSuccess) {
          uriAvatar = success.uri;
          removeAllImageSelected();
        }
      },
    );
  }

  void _handleUploadAvatarNewGroupChatOnDone() {
    Logs().d('NewGroupController::_handleUploadAvatarNewGroupChatOnDone() - done');
  }

  void _handleUploadAvatarNewGroupChatOnError(dynamic error, StackTrace? stackTrace) {
    Logs().e('NewGroupController::_handleUploadAvatarNewGroupChatOnError() - error: $error | stackTrace: $stackTrace');
  }

  void _handleCreateNewGroupChatChatOnData(BuildContext context, Either<Failure, Success> event) {
    Logs().d('NewGroupController::_handleCreateNewGroupChatChatOnData()');
    createRoomStateNotifier.value = event;
    event.fold(
      (failure) {
        Logs().e('NewGroupController::_handleCreateNewGroupChatChatOnData() - failure: $failure');
      },
      (success) {
        Logs().d('NewGroupController::_handleCreateNewGroupChatChatOnData() - success: $success');
        if (success is CreateNewGroupChatSuccess) {
          removeAllImageSelected();
          _goToRoom(context, success.roomId);
        }
      },
    );
  }

  void _handleCreateNewGroupChatOnDone() {
    Logs().d('NewGroupController::_handleCreateNewGroupChatOnDone() - done');
  }

  void _handleCreateNewGroupChatOnError(dynamic error, StackTrace? stackTrace) {
    Logs().e('NewGroupController::_handleUploadAvatarNewGroupChatOnError() - error: $error | stackTrace: $stackTrace');
  }

  void _goToRoom(BuildContext context, String roomId) {
    VRouter.of(context).toSegments(['rooms', roomId]);
  }

  Future<PermissionStatus>? _getCurrentPhotoPermission() {
    return PermissionHandlerService().requestPermissionForPhotoActions();
  }

  Future<PermissionStatus>? _getCurrentCameraPermission() {
    return PermissionHandlerService().requestPermissionForCameraActions();
  }

  void imagePickAction() async {
    Navigator.pop(context);
    final assetEntity = await CameraPicker.pickFromCamera(
      context,
      locale: window.locale,
    );
    if (assetEntity != null && assetEntity.type == AssetType.image) {
      uploadAvatarNewGroupChat(
        matrixClient: Matrix.of(context).client,
        entity: imagePickerController.selectedAssets.first.asset
      );
    }
  }

  void _registerListenerForSelectedImagesChanged() {
    imagePickerController.addListener(() {
      numberSelectedImagesNotifier.value = imagePickerController.selectedAssets.length;
    });

    numberSelectedImagesNotifier.addListener(() {
      if (numberSelectedImagesNotifier.value == 1) {
        Navigator.pop(context);
        uploadAvatarNewGroupChat(
          matrixClient: Matrix.of(context).client,
          entity: imagePickerController.selectedAssets.first.asset
        );
      }
    });
  }

  void saveAvatarAction(BuildContext context) async {

    final permissionStatusPhotos = await _getCurrentPhotoPermission();
    final permissionStatusCamera = await _getCurrentCameraPermission();

    if (permissionStatusCamera != null && permissionStatusPhotos != null) {
      await linagora_design_flutter.ImagePicker.showImagesGridBottomSheet(
        context: context,
        controller: imagePickerController,
        backgroundImageCamera: const AssetImage("assets/verification.png"),
        initialChildSize: 0.6,
        permissionStatus: permissionStatusPhotos,
        counterImageBuilder: (_) {
          return Column(
            children: [
              const SizedBox(height: 16.0,),
              Container(
                height: 4.0,
                width: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
        assetBackgroundColor: LinagoraSysColors.material().background,
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
            ? () => imagePickAction()
            : () => PermissionHandlerService().goToSettingsForPermissionActions(),
          backgroundImage: const AssetImage("assets/verification.png"),
        ),
      );
    }
  }

  void removeAllImageSelected() {
    imagePickerController.clearAssetCounter();
    numberSelectedImagesNotifier.value = 0;
    Logs().d('NewGroupController::_removeAllImageSelected() - numberSelectedImagesNotifier.value  ${numberSelectedImagesNotifier.value}');
  }

  @override
  Widget build(BuildContext context) => NewGroupView(this);
}
