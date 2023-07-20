import 'dart:collection';

import 'package:fluffychat/data/network/upload_file/upload_file_api.dart';
import 'package:fluffychat/di/base_di.dart';
import 'package:fluffychat/domain/usecase/download_file_for_preview_interactor.dart';
import 'package:fluffychat/domain/usecase/send_file_interactor.dart';
import 'package:fluffychat/domain/usecase/send_image_interactor.dart';
import 'package:fluffychat/domain/usecase/send_images_interactor.dart';
import 'package:get_it/get_it.dart';

class ChatScreenDi extends BaseDI {
  @override
  String get scopeName => "Chat";

  @override
  void setUp(GetIt get) {
    get.registerSingleton(UploadFileAPI());
    get.registerSingleton<SendImageInteractor>(SendImageInteractor());
    get.registerSingleton<SendImagesInteractor>(SendImagesInteractor());
    get.registerSingleton<DownloadFileForPreviewInteractor>(DownloadFileForPreviewInteractor());
    get.registerSingleton<SendFileInteractor>(SendFileInteractor());
  }
}