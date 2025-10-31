import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/extensions/xfile/xfile_extension.dart';
import 'package:fluffychat/presentation/mixins/pick_avatar_mixin.dart';
import 'package:fluffychat/presentation/model/pick_avatar_state.dart';
import 'package:flutter_test/flutter_test.dart';

class MockPickAvatarMixin with PickAvatarMixin {}

void main() {
  group(
    'pickAvatarMixin test on Web',
    () {
      late PickAvatarMixin mockPickAvatarMixin;

      setUp(
        () {
          mockPickAvatarMixin = MockPickAvatarMixin();
        },
      );

      test(
        'GIVEN pick file with size is 5MB'
        'THEN pickAvatarUIState should be GetAvatarOnWebUIStateSuccess',
        () async {
          final file = File('test1.png');
          await file.writeAsBytes(
            List.generate(5 * 1024 * 1024, (index) => index % 256),
          );
          final filePickerResult = FilePickerResult(
            [
              PlatformFile(
                name: 'test1.png',
                path: file.path,
                size: 5 * (1024 * 1024),
              ),
            ],
          );

          final matrixFile =
              await filePickerResult.xFiles.single.toMatrixFileOnWeb();

          await mockPickAvatarMixin.handlePickAvatarOnWeb(
            filePickerResult,
          );
          final result = mockPickAvatarMixin.pickAvatarUIState.value
              .getSuccessOrNull<GetAvatarOnWebUIStateSuccess>();

          expect(result?.matrixFile?.bytes, matrixFile.bytes);
          expect(result?.matrixFile?.name, matrixFile.name);
          expect(result?.matrixFile?.mimeType, matrixFile.mimeType);

          await file.delete();
        },
      );

      test(
        'GIVEN pick file with size is 11MB'
        'THEN pickAvatarUIState should be GetAvatarInitialUIState'
        'THEN show snackbar with message file too big',
        () async {
          final file = File('test1.png');
          await file.writeAsBytes(
            List.generate(11 * 1024 * 1024, (index) => index % 256),
          );
          final filePickerResult = FilePickerResult(
            [
              PlatformFile(
                name: 'test1.png',
                path: file.path,
                size: 11 * (1024 * 1024),
              ),
            ],
          );

          await mockPickAvatarMixin.handlePickAvatarOnWeb(
            filePickerResult,
          );

          expect(
            mockPickAvatarMixin.pickAvatarUIState.value.getFailureOrNull(),
            isA<GetAvatarBigSizeUIStateFailure>(),
          );

          await file.delete();
        },
      );
    },
  );
}
