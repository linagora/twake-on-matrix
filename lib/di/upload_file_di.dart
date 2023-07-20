import 'package:fluffychat/data/network/upload_file/upload_file_api.dart';
import 'package:fluffychat/di/base_di.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';

class UploadFileDI extends BaseDI {
  
  @override
  String get scopeName => 'Upload file';

  @override
  void setUp(GetIt get) {
    Logs().d('UploadFileDI::setUp()');

    get.registerSingleton<UploadFileAPI>(UploadFileAPI());

    Logs().d('UploadFileDI::setUp() - done');
  }
}