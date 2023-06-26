import 'dart:collection';

import 'package:fluffychat/di/base_di.dart';
import 'package:fluffychat/domain/usecase/download_file_for_preview_interactor.dart';
import 'package:fluffychat/domain/usecase/send_image_interactor.dart';
import 'package:fluffychat/domain/usecase/send_images_interactor.dart';
import 'package:get_it/get_it.dart';

class ChatScreenDi extends BaseDI {
  @override
  String get scopeName => "Send image";

  @override
  void setUp(GetIt get) {
    get.registerSingleton<Queue>(Queue());

    get.registerSingleton<SendImageInteractor>(SendImageInteractor());
    get.registerSingleton<SendImagesInteractor>(SendImagesInteractor());

    get.registerSingleton<DownloadFileForPreviewInteractor>(DownloadFileForPreviewInteractor());
  }
}