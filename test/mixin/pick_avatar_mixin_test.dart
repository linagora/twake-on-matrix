import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/domain/model/extensions/platform_file/platform_file_extension.dart';
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
          final filePickerResult = FilePickerResult(
            [
              PlatformFile(
                name: 'test1.png',
                size: 5 * (1024 * 1024),
                readStream: Stream.value(
                  List.generate(5 * 1024 * 1024, (index) => index % 256),
                ),
              ),
            ],
          );

          final matrixFile = filePickerResult.files.single.toMatrixFileOnWeb();

          mockPickAvatarMixin.handlePickAvatarOnWeb(
            filePickerResult,
          );

          expect(
            mockPickAvatarMixin.pickAvatarUIState.value,
            Right(GetAvatarOnWebUIStateSuccess(matrixFile: matrixFile)),
          );
        },
      );

      test(
        'GIVEN pick file with size is 11MB'
        'THEN pickAvatarUIState should be GetAvatarInitialUIState'
        'THEN show snackbar with message file too big',
        () async {
          final filePickerResult = FilePickerResult(
            [
              PlatformFile(
                name: 'test1.png',
                size: 11 * (1024 * 1024),
                readStream: Stream.value(
                  List.generate(11 * 1024 * 1024, (index) => index % 256),
                ),
              ),
            ],
          );

          mockPickAvatarMixin.handlePickAvatarOnWeb(
            filePickerResult,
          );

          expect(
            mockPickAvatarMixin.pickAvatarUIState.value,
            const Left(GetAvatarBigSizeUIStateFailure()),
          );
        },
      );
    },
  );
}
