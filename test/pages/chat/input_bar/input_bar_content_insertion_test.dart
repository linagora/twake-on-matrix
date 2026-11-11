import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:twake_chat/pages/chat/input_bar/input_bar.dart';

void main() {
  testWidgets('an image from the keyboard reaches onPasteImages', (
    tester,
  ) async {
    final pasted = <MatrixFile>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
        home: Scaffold(
          body: InputBar(
            controller: TextEditingController(),
            focusSuggestionController: FocusSuggestionController(),
            onPasteImages: pasted.addAll,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.idle();

    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/textinput',
      const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[
          -1,
          'TextInputAction.commitContent',
          jsonDecode(
            '{"mimeType": "image/png", "data": [1, 2, 3], '
            '"uri": "content://keyboard/image.png"}',
          ),
        ],
        'method': 'TextInputClient.performAction',
      }),
      (_) {},
    );

    expect(pasted, hasLength(1));
    expect(pasted.single, isA<MatrixImageFile>());
    expect(pasted.single.mimeType, 'image/png');
    expect(pasted.single.bytes, [1, 2, 3]);
    await tester.pump(const Duration(seconds: 1));
  });
}
