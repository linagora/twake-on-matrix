import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:photo_manager/photo_manager.dart';
import '../robots/chat_group_detail_robot.dart';

Future<void> allowPhotosIfNeeded(PatrolIntegrationTester $) async {
  const springboardId = 'com.apple.springboard';
  final allowFullAccessButton = NativeSelector(ios: IOSSelector(elementType: IOSElementType.button,instance: 1,),);

  try{
    await $.native2.waitUntilVisible(allowFullAccessButton,appId: springboardId,timeout: const Duration(seconds: 3),);
    await $.native2.tap(allowFullAccessButton,appId: springboardId,);
  }
  catch (_) {}
}

Future<void> maybeTapFirstV1(PatrolIntegrationTester $, List<Selector> opts) async {
  for (final s in opts) { try { await $.native.tap(s); return; } catch (_) {} }
}

Future<void> selectFileInDownloads(
  PatrolIntegrationTester $,
  String fileName,
) async {
  for (final s in <Selector>[
    Selector(text: fileName),
    Selector(textContains: fileName),
    Selector(className: 'UILabel', text: fileName),
    Selector(className: 'UILabel', textContains: fileName),
  ])
  {
    try {
      await $.native.waitUntilVisible(s, timeout: const Duration(seconds: 5));
      await $.native.tap(s);
      
      final openButton = NativeSelector(ios: IOSSelector(elementType: IOSElementType.button,instance: 3,),);
      await $.native2.waitUntilVisible(openButton,appId: null,timeout: const Duration(seconds: 5),);
      await $.native2.tap(openButton,appId: null,);
      return;
    } catch (_) {}
  }

  throw Exception('not found the table item with label "$fileName"');

}

Future<bool> existsNative(
  PatrolIntegrationTester $,
  Selector selector, {
  Duration timeout = const Duration(milliseconds: 500),
}) async {
  try {
    await $.native.waitUntilVisible(selector, timeout: timeout);
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> openDownloadFolder(PatrolIntegrationTester $) async {
  // Tab "Documents"
  try {
    await $.waitUntilVisible($(Text).containing('Documents'));
    await $(Text).containing('Documents').tap();
  } catch (_) {
    await maybeTapFirstV1($, [Selector(textContains: 'Documents')]);
  }
  await $.tester.pump(const Duration(milliseconds: 300));

  // Make sure we’re on the “Browse” tab in the Files picker
  if (await existsNative($, Selector(textContains: 'On My iPhone'))) {
    return;
  }

  // Check the existence before clicking on "Downloads"
  final downloadsTile = Selector(text: 'Downloads', instance: 1);
  try {
    await $.native.waitUntilVisible(downloadsTile, timeout: const Duration(seconds: 2));
    // "Downloads"
    await maybeTapFirstV1($, [
      Selector(textContains: 'Downloads'),
      Selector(textContains: 'Tải về'),
    ]);
  await $.tester.pump(const Duration(milliseconds: 400));
  } catch (_) {
  }

  await $.native.waitUntilVisible(Selector(text: 'Search'), timeout: const Duration(seconds: 5));
}

Future<void> pickFromFiles(PatrolIntegrationTester $, String fileName) async {
  await openDownloadFolder($);

  // Choose the file
  await selectFileInDownloads($, fileName);
  await $.waitUntilVisible(ChatGroupDetailRobot($).getInputTextField());
}

Future<int> countItemsInGallery(PatrolIntegrationTester $) async {
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image, onlyAll: true);
    await allowPhotosIfNeeded($);
    final recents = albums.first;
    final total = await recents.assetCountAsync;
    return total;
  }

Future<bool> isImageSaved(String fileName) async {
  // get list of albums
  final albums = await PhotoManager.getAssetPathList(
    type: RequestType.image,
    onlyAll: true,
  );

  final recents = albums.first;

  // get all assets in album Recents (or All Photos)
  final assets = await recents.getAssetListPaged(page: 0, size: 200);

  // Check the existence of the fileName
  final found = assets.any((asset) => asset.title?.contains(fileName) ?? false);

  return found;
}
