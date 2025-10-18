import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:photo_manager/photo_manager.dart';
import '../robots/chat_group_detail_robot.dart';

const _sb = 'com.apple.springboard';
Future<void> allowPhotosIfNeeded(PatrolIntegrationTester $) async {
   final titles = <Selector>[
    Selector(textContains: 'Would Like to Access Your Photo Library'),
    Selector(textContains: 'muốn truy cập Ảnh'),
    Selector(textContains: 'Thư viện ảnh'),
  ];

  final allows = <Selector>[
    Selector(textContains: 'Allow Full Access'),
    Selector(textContains: 'Allow Access to All Photos'),
    Selector(textContains: 'All Photos'),
    Selector(text: 'Allow'),
    Selector(text: 'OK'),
    Selector(textContains: 'Cho phép'),
    Selector(textContains: 'Toàn bộ ảnh'),
  ];

  // 1) wait for display SpringBoard
  bool visible = false;
  for (final t in titles) {
    try {
      await $.native.waitUntilVisible(t, appId: _sb, timeout: const Duration(seconds: 6));
      visible = true;
      break;
    } catch (_) {}
  }
  if (!visible) return;

  // 2) tab on Allow button (on SpringBoard)
  for (final a in allows) {
    try { await $.native.tap(a, appId: _sb); break; } catch (_) {}
  }

  // 3) wait for disappear of SpringBoard
  final end = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(end)) {
    var stillVisible = false;
    for (final t in titles) {
      try {
        await $.native.waitUntilVisible(t, appId: _sb, timeout: const Duration(milliseconds: 300));
        stillVisible = true; 
        break;
      } catch (_) {
      }
    }
    if (!stillVisible) break;
    await Future.delayed(const Duration(milliseconds: 200));
  }

  await $.tester.pumpAndSettle();
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
  ]) {
    try {
      await $.native.waitUntilVisible(s, timeout: const Duration(seconds: 3));
      await $.native.tap(s);
      // Xác nhận nếu có
      await maybeTapFirstV1($, [
        Selector(text: 'Open'),
        Selector(text: 'Choose'),
        Selector(text: 'Chọn'),
        Selector(text: 'Mở'),
      ]);
      return;
    } catch (_) {}
  }

  throw Exception('ot found the table item with label "$fileName"');

}

Future<void> openDownloadFolder(PatrolIntegrationTester $) async {
  // Tab "Documents"
  try {
    await $(Text).containing('Documents').tap();
  } catch (_) {
    await maybeTapFirstV1($, [Selector(textContains: 'Documents')]);
  }
  await $.tester.pump(const Duration(milliseconds: 300));

// 1) Check the existence before clicking on "Downloads"
  final downloadsTile = Selector(text: 'Downloads', instance: 1);
  try {
    await $.native.waitUntilVisible(downloadsTile, timeout: const Duration(seconds: 2));
    // await $.native.tap(downloadsTile);
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
