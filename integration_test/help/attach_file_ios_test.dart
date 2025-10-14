import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
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

Future<void> pickFromFiles(PatrolIntegrationTester $, String fileName) async {
  // Tab "Documents"
  try {
    await $(Text).containing('Documents').tap();
  } catch (_) {
    await maybeTapFirstV1($, [Selector(textContains: 'Documents')]);
  }
  await $.tester.pump(const Duration(milliseconds: 300));

  // "Downloads"
  await maybeTapFirstV1($, [
    Selector(textContains: 'Downloads'),
    Selector(textContains: 'Tải về'),
  ]);
  await $.tester.pump(const Duration(milliseconds: 400));

  // Choose the file
  await selectFileInDownloads($, fileName);
  await $.waitUntilVisible(ChatGroupDetailRobot($).getInputTextField());
}